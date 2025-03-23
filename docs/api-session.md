# Captured API session

Every block below is a real request against the Docker Compose stack
(`docker compose up --build`: the production image on Ruby 3.4.12 and Rails
8.1, PostgreSQL 17, seeded on first boot). Commands and status lines are
verbatim; JSON bodies are pretty-printed and otherwise unedited.

```console
$ docker compose exec app ruby -v
ruby 3.4.12 (2026-10-23 revision 366f5fdc00) +PRISM [aarch64-linux]
$ docker compose logs app | grep Seeded
Seeded 3 glossaries, 12 terms, 4 translations.
```

## Health

### Liveness probe, also used by the container healthcheck

```console
$ curl http://localhost:8380/health
HTTP 200
{
  "status": "ok",
  "database": "ok",
  "markup_styles": [
    "highlight",
    "mark",
    "brackets"
  ],
  "matching_strategies": [
    "automaton",
    "regexp",
    "adaptive"
  ]
}
```

## Glossaries

### List glossaries (seeded), page metadata in headers

```console
$ curl 'http://localhost:8380/glossaries?per_page=2'
HTTP 200
[
  {
    "id": 1,
    "source_language_code": "en",
    "target_language_code": "fr",
    "case_sensitive": true,
    "terms": [
      {
        "id": 1,
        "source_term": "cat",
        "target_term": "chat"
      },
      {
        "id": 2,
        "source_term": "dog",
        "target_term": "chien"
      },
      {
        "id": 3,
        "source_term": "New York",
        "target_term": "New York"
      },
      {
        "id": 4,
        "source_term": "ice cream",
        "target_term": "glace"
      },
      {
        "id": 5,
        "source_term": "open source",
        "target_term": "logiciel libre"
      },
      {
        "id": 6,
        "source_term": "machine translation",
        "target_term": "traduction automatique"
      }
    ]
  },
  {
    "id": 2,
    "source_language_code": "en",
    "target_language_code": "de",
    "case_sensitive": false,
    "terms": [
      {
        "id": 7,
        "source_term": "cat",
        "target_term": "Katze"
      },
      {
        "id": 8,
        "source_term": "dog",
        "target_term": "Hund"
      },
      {
        "id": 9,
        "source_term": "release notes",
        "target_term": "Versionshinweise"
      },
      {
        "id": 10,
        "source_term": "pull request",
        "target_term": "Pull-Request"
      }
    ]
  }
]
```

### The paging headers for the same request

```console
$ curl -sS -D - -o /dev/null 'http://localhost:8380/glossaries?per_page=2' | grep -i '^x-\(page\|per-page\|total\)'
x-page: 1
x-per-page: 2
x-total-count: 3
x-total-pages: 2
```

### Fetch one glossary with its terms

```console
$ curl http://localhost:8380/glossaries/1
HTTP 200
{
  "id": 1,
  "source_language_code": "en",
  "target_language_code": "fr",
  "case_sensitive": true,
  "terms": [
    {
      "id": 1,
      "source_term": "cat",
      "target_term": "chat"
    },
    {
      "id": 2,
      "source_term": "dog",
      "target_term": "chien"
    },
    {
      "id": 3,
      "source_term": "New York",
      "target_term": "New York"
    },
    {
      "id": 4,
      "source_term": "ice cream",
      "target_term": "glace"
    },
    {
      "id": 5,
      "source_term": "open source",
      "target_term": "logiciel libre"
    },
    {
      "id": 6,
      "source_term": "machine translation",
      "target_term": "traduction automatique"
    }
  ]
}
```

### Create a glossary

```console
$ curl -X POST http://localhost:8380/glossaries -H 'Content-Type: application/json' -d '{"glossary":{"source_language_code":"en","target_language_code":"es"}}'
HTTP 201
{
  "id": 4,
  "source_language_code": "en",
  "target_language_code": "es",
  "case_sensitive": true,
  "terms": []
}
```

### Duplicate language pair is rejected

```console
$ curl -X POST http://localhost:8380/glossaries -H 'Content-Type: application/json' -d '{"glossary":{"source_language_code":"en","target_language_code":"es"}}'
HTTP 422
{
  "source_language_code": [
    "has already been taken"
  ]
}
```

### Add a term to the new glossary; surrounding spaces are stripped

```console
$ curl -X POST http://localhost:8380/glossaries/4/terms -H 'Content-Type: application/json' -d '{"term":{"source_term":" open source ","target_term":"codigo abierto"}}'
HTTP 201
{
  "id": 13,
  "source_term": "open source",
  "target_term": "codigo abierto"
}
```

### The same source term twice in one glossary is rejected

```console
$ curl -X POST http://localhost:8380/glossaries/4/terms -H 'Content-Type: application/json' -d '{"term":{"source_term":"open source","target_term":"fuente abierta"}}'
HTTP 422
{
  "source_term": [
    "has already been taken"
  ]
}
```

### Unknown glossary returns 404, not a 500

```console
$ curl -X POST http://localhost:8380/glossaries/999999/terms -H 'Content-Type: application/json' -d '{"term":{"source_term":"cat","target_term":"gato"}}'
HTTP 404
{
  "errors": "Glossary not found"
}
```

## Translations and highlighting

### Create a translation against glossary 1 (en -> fr)

```console
$ curl -X POST http://localhost:8380/translations -H 'Content-Type: application/json' -d '{"translation":{"source_language_code":"en","target_language_code":"fr","glossary_id":1,"source_text":"The cat ate ice cream in New York, and the dogged concatenation stayed put."}}'
HTTP 201
{
  "id": 5,
  "source_language_code": "en",
  "target_language_code": "fr",
  "source_text": "The cat ate ice cream in New York, and the dogged concatenation stayed put.",
  "glossary_id": 1
}
```

### Read it back: glossary terms are wrapped, near-misses are not

```console
$ curl http://localhost:8380/translations/5
HTTP 200
{
  "id": 5,
  "source_language_code": "en",
  "target_language_code": "fr",
  "source_text": "The <HIGHLIGHT>cat</HIGHLIGHT> ate <HIGHLIGHT>ice cream</HIGHLIGHT> in <HIGHLIGHT>New York</HIGHLIGHT>, and the dogged concatenation stayed put.",
  "glossary_id": 1
}
```

### Same translation, HTML mark markup

```console
$ curl 'http://localhost:8380/translations/5?markup=mark'
HTTP 200
{
  "id": 5,
  "source_language_code": "en",
  "target_language_code": "fr",
  "source_text": "The <mark>cat</mark> ate <mark>ice cream</mark> in <mark>New York</mark>, and the dogged concatenation stayed put.",
  "glossary_id": 1
}
```

### Same translation, bracket markup

```console
$ curl 'http://localhost:8380/translations/5?markup=brackets'
HTTP 200
{
  "id": 5,
  "source_language_code": "en",
  "target_language_code": "fr",
  "source_text": "The [[cat]] ate [[ice cream]] in [[New York]], and the dogged concatenation stayed put.",
  "glossary_id": 1
}
```

### Unregistered markup is rejected with the list of registered ones

```console
$ curl 'http://localhost:8380/translations/5?markup=neon'
HTTP 422
{
  "errors": "unknown markup \"neon\" (known: highlight, mark, brackets)"
}
```

### Case-insensitive glossary (en -> de): 'Cat' and 'DOG' both match

```console
$ curl http://localhost:8380/translations/2
HTTP 200
{
  "id": 2,
  "source_language_code": "en",
  "target_language_code": "de",
  "source_text": "A <HIGHLIGHT>Cat</HIGHLIGHT>, a <HIGHLIGHT>DOG</HIGHLIGHT> and the <HIGHLIGHT>release notes</HIGHLIGHT> are in the <HIGHLIGHT>pull request</HIGHLIGHT>.",
  "glossary_id": 2
}
```

### Multi-word term in a case-sensitive glossary (es -> en)

```console
$ curl http://localhost:8380/translations/3
HTTP 200
{
  "id": 3,
  "source_language_code": "es",
  "target_language_code": "en",
  "source_text": "El <HIGHLIGHT>gato</HIGHLIGHT> prefiere el <HIGHLIGHT>código abierto</HIGHLIGHT>.",
  "glossary_id": 3
}
```

### No glossary attached: text is returned verbatim

```console
$ curl http://localhost:8380/translations/4
HTTP 200
{
  "id": 4,
  "source_language_code": "en",
  "target_language_code": "fr",
  "source_text": "This sentence has no glossary attached at all.",
  "glossary_id": null
}
```

## Validation and error handling

### glossary_id that points at no row is rejected, not stored

```console
$ curl -X POST http://localhost:8380/translations -H 'Content-Type: application/json' -d '{"translation":{"source_language_code":"en","target_language_code":"fr","glossary_id":999999,"source_text":"hello"}}'
HTTP 422
{
  "glossary": [
    "must exist"
  ]
}
```

### Glossary language pair must match the translation's

```console
$ curl -X POST http://localhost:8380/translations -H 'Content-Type: application/json' -d '{"translation":{"source_language_code":"de","target_language_code":"fr","glossary_id":1,"source_text":"hello"}}'
HTTP 422
{
  "glossary": [
    "language codes do not match with the source and target language codes"
  ]
}
```

### Missing top-level key returns 400

```console
$ curl -X POST http://localhost:8380/translations -H 'Content-Type: application/json' -d '{"source_text":"hello"}'
HTTP 400
{
  "errors": "Required parameter missing: translation"
}
```

### A wrapper key holding a string instead of an object is a 400 too

```console
$ curl -X POST http://localhost:8380/glossaries/1/terms -H 'Content-Type: application/json' -d '{"term":"cat"}'
HTTP 400
{
  "errors": "Required parameter missing: term"
}
```

### A body that is not JSON gets the same error shape

```console
$ curl -X POST http://localhost:8380/glossaries -H 'Content-Type: application/json' -d '{"glossary": {'
HTTP 400
{
  "errors": "Request body is not valid JSON"
}
```

### case_sensitive must be a boolean, not null

```console
$ curl -X POST http://localhost:8380/glossaries -H 'Content-Type: application/json' -d '{"glossary":{"source_language_code":"en","target_language_code":"it","case_sensitive":null}}'
HTTP 422
{
  "case_sensitive": [
    "must be true or false"
  ]
}
```

### Query parameters of the wrong shape are not a 500

```console
$ curl 'http://localhost:8380/translations/5?markup[]=mark'
HTTP 422
{
  "errors": "markup must be a single name (known: highlight, mark, brackets)"
}
```

### A page number past what the database can offset is capped

```console
$ curl -sS -D - -o /dev/null 'http://localhost:8380/glossaries?page=99999999999999999999' | grep -i '^\(HTTP\|x-page\)'
HTTP/1.1 200 OK
x-page: 1000000
```

### Unknown translation returns 404

```console
$ curl http://localhost:8380/translations/999999
HTTP 404
{
  "errors": "Translation not found"
}
```

## Limits

### A request body over the cap is refused before Rails parses it

```console
$ { printf '{"translation":{"source_text":"'; head -c 2000000 /dev/zero | tr '\0' 'a'; printf '"}}'; } > /tmp/big.json
$ wc -c < /tmp/big.json | tr -d ' '
2000034
$ curl -sS -w '\n%{http_code}\n' -X POST http://localhost:8380/translations -H 'Content-Type: application/json' --data-binary @/tmp/big.json
{"errors":"Request body too large (limit 1048576 bytes)"}
413
```

### Per-IP rate limiting (120 reads/minute by default)

The reads above already used part of this minute's budget, so the burst is refused before its 125th request.

```console
$ for i in $(seq 1 125); do curl -sS -o /dev/null -w '%{http_code} ' http://localhost:8380/glossaries; done | fold -w 80
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
200 200 200 200 200 200 200 429 429 429 429 429 429 429 429 429 429 429 429 429 
429 429 429 429 429 
$ curl -sS -D - -o /dev/null http://localhost:8380/glossaries | grep -i '^\(HTTP\|retry-after\)'
HTTP/1.1 429 Too Many Requests
retry-after: 60
$ curl -sS http://localhost:8380/glossaries
{"errors":"Rate limit exceeded. Retry in 60 seconds."}
$ curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:8380/health   # health checks are safelisted
200
```
