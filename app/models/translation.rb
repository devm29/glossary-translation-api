# == Schema Information
#
# Table name: translations
#
#  id                   :bigint           not null, primary key
#  source_language_code :string           not null
#  target_language_code :string           not null
#  source_text          :string(5000)     not null
#  glossary_id          :bigint
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Translation < ApplicationRecord
  belongs_to :glossary, optional: true
  validates :source_language_code, presence: true, inclusion: {in: Glossary::ISO_639_1_CODES}
  validates :target_language_code, presence: true, inclusion: {in: Glossary::ISO_639_1_CODES}
  validates :source_text, presence: true, length: {maximum: 5000}
  validate :glossary_must_exist
  validate :glossary_match_languages

  private

  # `belongs_to ..., optional: true` accepts a glossary_id that points at no
  # row. The foreign key would reject it too, but only as a 500 from the
  # database; this turns it into a 422 with a field error.
  def glossary_must_exist
    return if glossary_id.blank? || glossary.present?

    errors.add(:glossary, "must exist")
  end

  def glossary_match_languages
    if glossary.present? && (source_language_code != glossary.source_language_code || target_language_code != glossary.target_language_code)
      errors.add(:glossary, "language codes do not match with the source and target language codes")
    end
  end
end
