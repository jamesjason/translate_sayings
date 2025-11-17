# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_17_222313) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "languages", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_languages_on_code", unique: true
    t.check_constraint "code::text ~ '^[a-z]+$'::text", name: "languages_code_lowercase_no_spaces"
  end

  create_table "saying_translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "saying_a_id", null: false
    t.bigint "saying_b_id", null: false
    t.datetime "updated_at", null: false
    t.index "LEAST(saying_a_id, saying_b_id), GREATEST(saying_a_id, saying_b_id)", name: "index_saying_translations_on_normalized_pair", unique: true
    t.index ["saying_a_id"], name: "index_saying_translations_on_saying_a_id"
    t.index ["saying_b_id"], name: "index_saying_translations_on_saying_b_id"
    t.check_constraint "saying_a_id <> saying_b_id", name: "saying_translations_a_and_b_must_differ"
  end

  create_table "sayings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "language_id", null: false
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index "lower(text)", name: "index_sayings_on_lower_text_unique", unique: true
    t.index ["language_id"], name: "index_sayings_on_language_id"
  end

  add_foreign_key "saying_translations", "sayings", column: "saying_a_id"
  add_foreign_key "saying_translations", "sayings", column: "saying_b_id"
  add_foreign_key "sayings", "languages"
end
