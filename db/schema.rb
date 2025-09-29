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

ActiveRecord::Schema[8.0].define(version: 2025_09_29_150923) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "lessons", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.string "type", null: false
    t.json "data", default: {}, null: false
    t.integer "position", null: false
    t.bigint "level_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id", "position"], name: "index_lessons_on_level_id_and_position", unique: true
    t.index ["level_id"], name: "index_lessons_on_level_id"
    t.index ["slug"], name: "index_lessons_on_slug", unique: true
    t.index ["type"], name: "index_lessons_on_type"
  end

  create_table "levels", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_levels_on_position", unique: true
    t.index ["slug"], name: "index_levels_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "jti", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "lessons", "levels"
end
