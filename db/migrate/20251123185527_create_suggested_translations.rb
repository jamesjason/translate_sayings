class CreateSuggestedTranslations < ActiveRecord::Migration[8.1]
  def change
    create_table :suggested_translations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :source_language, null: false, foreign_key: { to_table: :languages }
      t.references :target_language, null: false, foreign_key: { to_table: :languages }
      t.text :source_saying_text, null: false
      t.text :target_saying_text, null: false
      t.string :status, null: false, default: 'pending_review'

      t.timestamps
    end
  end
end
