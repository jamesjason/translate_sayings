class CreateSayingTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :saying_translations do |t|
      t.references :saying_a, null: false, foreign_key: { to_table: :sayings }
      t.references :saying_b, null: false, foreign_key: { to_table: :sayings }

      t.timestamps
    end

    add_check_constraint :saying_translations,
      "saying_a_id <> saying_b_id",
      name: "saying_translations_a_and_b_must_differ"

    add_index :saying_translations,
      "LEAST(saying_a_id, saying_b_id), GREATEST(saying_a_id, saying_b_id)",
      unique: true,
      name: "index_saying_translations_on_normalized_pair"
  end
end
