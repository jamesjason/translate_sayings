class CreateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :languages do |t|
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end

    add_index :languages, :code, unique: true

    add_check_constraint :languages,
      "code ~ '^[a-z]+$'",
      name: "languages_code_lowercase_no_spaces"
  end
end
