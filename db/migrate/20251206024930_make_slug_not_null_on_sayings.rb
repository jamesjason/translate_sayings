class MakeSlugNotNullOnSayings < ActiveRecord::Migration[8.1]
  def change
    change_column_null :sayings, :slug, false
  end
end
