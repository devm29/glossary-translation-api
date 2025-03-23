module Highlighting
  # The alternation-of-literals approach this endpoint started with. Onigmo
  # scans the union in C, which is why AdaptiveMatcher picks it for every
  # glossary below HIGHLIGHT_AUTOMATON_THRESHOLD.
  #
  # Its cost grows with the number of alternatives, so a large glossary goes to
  # the automaton instead. The "strategy parity on random input" block in
  # spec/domain/highlighting/matcher_spec.rb keeps the two in agreement, and
  # `rake benchmark:highlighting` measures one against the other.
  class RegexpMatcher < Matcher
    private

    def prepare
      return if terms.empty?

      # Longest first so that, at a given position, the longest alternative is
      # the one tried first.
      union = Regexp.union(terms.sort_by { |term| -term.length })
      @pattern = /(?<!\w)#{union}(?!\w)/
    end

    def raw_matches(folded)
      text = folded.string
      found = []
      position = 0

      while (match = @pattern.match(text, position))
        found << [match.begin(0), match[0].length]
        position = match.begin(0) + match[0].length
      end
      found
    end
  end
end
