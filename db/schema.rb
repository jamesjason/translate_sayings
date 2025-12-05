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

ActiveRecord::Schema[8.1].define(version: 2025_12_05_173346) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

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
    t.text "normalized_text", null: false
    t.string "slug"
    t.text "text", null: false
    t.datetime "updated_at", null: false
    t.index "lower(text)", name: "index_sayings_on_lower_text_unique", unique: true
    t.index ["language_id"], name: "index_sayings_on_language_id"
    t.index ["normalized_text"], name: "index_sayings_on_normalized_text", opclass: :gin_trgm_ops, using: :gin
    t.index ["slug"], name: "index_sayings_on_slug"
    t.index ["text"], name: "index_sayings_on_text_gin_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "suggested_translations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "source_language_id", null: false
    t.text "source_saying_text", null: false
    t.string "status", default: "pending_review", null: false
    t.bigint "target_language_id", null: false
    t.text "target_saying_text", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["source_language_id"], name: "index_suggested_translations_on_source_language_id"
    t.index ["target_language_id"], name: "index_suggested_translations_on_target_language_id"
    t.index ["user_id"], name: "index_suggested_translations_on_user_id"
  end

  create_table "translation_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "saying_translation_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "vote", default: 0, null: false
    t.index ["saying_translation_id"], name: "index_translation_votes_on_saying_translation_id"
    t.index ["user_id", "saying_translation_id"], name: "index_translation_votes_on_user_id_and_saying_translation_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "user", null: false
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "saying_translations", "sayings", column: "saying_a_id"
  add_foreign_key "saying_translations", "sayings", column: "saying_b_id"
  add_foreign_key "sayings", "languages"
  add_foreign_key "suggested_translations", "languages", column: "source_language_id"
  add_foreign_key "suggested_translations", "languages", column: "target_language_id"
  add_foreign_key "suggested_translations", "users"
  add_foreign_key "translation_votes", "saying_translations"
  add_foreign_key "translation_votes", "users"
end
