class AddUniqueIndexToSayingsText < ActiveRecord::Migration[8.1]
  def change
    add_index :sayings,
              'LOWER(text)',
              unique: true,
              name: 'index_sayings_on_lower_text_unique'
  end
end
