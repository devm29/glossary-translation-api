require "rails_helper"

RSpec.describe Term, type: :model do
  describe "associations" do
    it { should belong_to(:glossary) }
  end

  describe "validations" do
    it { should validate_presence_of(:source_term) }
    it { should validate_presence_of(:target_term) }

    it "rejects a second term with the same source term in one glossary" do
      glossary = create(:glossary)
      create(:term, glossary: glossary, source_term: "cat", target_term: "chat")

      duplicate = build(:term, glossary: glossary, source_term: "cat", target_term: "matou")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:source_term]).to include("has already been taken")
    end

    it "allows the same source term in another glossary" do
      create(:term, glossary: create(:glossary, target_language_code: "fr"), source_term: "cat")

      expect(build(:term, glossary: create(:glossary, target_language_code: "de"), source_term: "cat")).to be_valid
    end
  end

  describe "normalization" do
    it "strips surrounding whitespace so padding is never matched as part of the term" do
      term = create(:term, source_term: "  ice cream ", target_term: " glace ")

      expect(term.reload).to have_attributes(source_term: "ice cream", target_term: "glace")
    end

    it "treats a whitespace-only source term as blank" do
      expect(build(:term, source_term: "   ")).not_to be_valid
    end
  end
end
