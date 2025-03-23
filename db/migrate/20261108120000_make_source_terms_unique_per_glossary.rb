# A glossary could hold "cat" twice with different target terms, and a term
# padded with spaces matched the spaces around it. The model now strips and
# rejects both; this cleans existing rows the same way, keeping the oldest of
# each duplicate, and makes the database enforce it.
class MakeSourceTermsUniquePerGlossary < ActiveRecord::Migration[8.1]
  INDEX = "index_terms_on_glossary_id_and_source_term"

  def up
    execute("UPDATE terms SET source_term = TRIM(source_term), target_term = TRIM(target_term)")
    execute(<<~SQL)
      DELETE FROM terms
       WHERE id IN (
         SELECT id FROM (
           SELECT id, ROW_NUMBER() OVER (PARTITION BY glossary_id, source_term ORDER BY id) AS position
             FROM terms
         ) ranked
          WHERE position > 1
       )
    SQL

    remove_index :terms, name: INDEX
    add_index :terms, %i[glossary_id source_term], unique: true, name: INDEX
  end

  def down
    remove_index :terms, name: INDEX
    add_index :terms, %i[glossary_id source_term], name: INDEX
  end
end
