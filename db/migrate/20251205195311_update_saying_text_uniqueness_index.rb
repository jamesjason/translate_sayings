class UpdateSayingTextUniquenessIndex < ActiveRecord::Migration[8.1]
  def up
    remove_index :sayings, name: 'index_sayings_on_lower_text_unique'

    add_index :sayings,
              %i[language_id text],
              unique: true,
              name: 'index_sayings_on_language_and_text_unique'
  end

  def down
    remove_index :sayings, name: 'index_sayings_on_language_and_text_unique'

    add_index :sayings,
              'lower(text)',
              unique: true,
              name: 'index_sayings_on_lower_text_unique'
  end
end
