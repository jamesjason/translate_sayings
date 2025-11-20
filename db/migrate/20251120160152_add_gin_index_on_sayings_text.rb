class AddGinIndexOnSayingsText < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pg_trgm' unless extension_enabled?('pg_trgm')

    add_index :sayings, :text, using: :gin, opclass: :gin_trgm_ops,
                               name: 'index_sayings_on_text_gin_trgm'
  end
end
