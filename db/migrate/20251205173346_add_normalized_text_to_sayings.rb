class AddNormalizedTextToSayings < ActiveRecord::Migration[8.1]
  def change
    add_column :sayings, :normalized_text, :text, null: false # rubocop:disable Rails/NotNullColumn
    add_index  :sayings, :normalized_text, using: :gin, opclass: :gin_trgm_ops
  end
end
