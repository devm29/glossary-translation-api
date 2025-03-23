FactoryBot.define do
  factory :term do
    # Unique within a glossary, which a random word is not guaranteed to be.
    sequence(:source_term) { |n| "term#{n}" }
    target_term { Faker::Lorem.word }
    glossary { create(:glossary) }
  end
end
