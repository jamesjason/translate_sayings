class AddSlugToSayings < ActiveRecord::Migration[8.1]
  def change
    add_column :sayings, :slug, :string
    add_index :sayings, :slug
  end
end
