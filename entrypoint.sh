#!/bin/bash
set -euo pipefail

# Remove a stale pidfile left by a container that did not shut down cleanly.
rm -f /app/tmp/pids/server.pid

# db:prepare creates the database, loads db/schema.rb and runs db/seeds.rb the
# first time, and applies pending migrations on every later boot, so the app is
# never empty on first boot and never re-seeded on the next one.
if [ "${SKIP_DB_SETUP:-}" != "1" ]; then
  bundle exec rails db:prepare
fi

exec "$@"
