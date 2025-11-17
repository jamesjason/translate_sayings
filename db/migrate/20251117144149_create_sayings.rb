class CreateSayings < ActiveRecord::Migration[8.1]
  def change
    create_table :sayings do |t|
      t.references :language, null: false, foreign_key: true
      t.text :text, null: false

      t.timestamps
    end
  end
end
