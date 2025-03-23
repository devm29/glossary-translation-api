module Highlighting
  # Builds one Aho-Corasick automaton per term set and scans the text in a
  # single pass, so match time is O(text length) regardless of how many terms
  # the glossary holds. AdaptiveMatcher only picks it for large glossaries,
  # because the pure-Ruby scan loses to RegexpMatcher below that size.
  class AutomatonMatcher < Matcher
    private

    def prepare
      @automaton = Automaton.new(terms)
    end

    def raw_matches(folded)
      @automaton.scan(folded.code_points)
    end
  end
end
