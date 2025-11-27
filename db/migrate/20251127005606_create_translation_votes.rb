class CreateTranslationVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :translation_votes do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :saying_translation, null: false, foreign_key: true
      t.integer :vote, null: false, default: 0

      t.timestamps
    end

    add_index :translation_votes,
              %i[user_id saying_translation_id],
              unique: true
  end
end
