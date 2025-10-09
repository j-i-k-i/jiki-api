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

ActiveRecord::Schema[8.0].define(version: 2025_10_09_124423) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "email_templates", force: :cascade do |t|
    t.integer "template_type", null: false
    t.string "key"
    t.string "locale", null: false
    t.text "subject", null: false
    t.text "body_mjml", null: false
    t.text "body_text", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["template_type", "key", "locale"], name: "index_email_templates_on_template_type_and_key_and_locale", unique: true
  end

  create_table "exercise_submission_files", force: :cascade do |t|
    t.bigint "exercise_submission_id", null: false
    t.string "filename", null: false
    t.string "digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_submission_id"], name: "index_exercise_submission_files_on_exercise_submission_id"
  end

  create_table "exercise_submissions", force: :cascade do |t|
    t.bigint "user_lesson_id", null: false
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_lesson_id"], name: "index_exercise_submissions_on_user_lesson_id"
    t.index ["uuid"], name: "index_exercise_submissions_on_uuid", unique: true
  end

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

  create_table "user_jwt_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "jti", null: false
    t.string "aud"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_user_jwt_tokens_on_expires_at"
    t.index ["jti"], name: "index_user_jwt_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_user_jwt_tokens_on_user_id"
  end

  create_table "user_lessons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "lesson_id", null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["lesson_id"], name: "index_user_lessons_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_user_lessons_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_user_lessons_on_user_id"
  end

  create_table "user_levels", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "level_id", null: false
    t.bigint "current_user_lesson_id"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "email_status", default: 0, null: false
    t.index ["current_user_lesson_id"], name: "index_user_levels_on_current_user_lesson_id"
    t.index ["level_id"], name: "index_user_levels_on_level_id"
    t.index ["user_id", "level_id"], name: "index_user_levels_on_user_id_and_level_id", unique: true
    t.index ["user_id"], name: "index_user_levels_on_user_id"
  end

  create_table "user_refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "crypted_token", null: false
    t.string "aud"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["crypted_token"], name: "index_user_refresh_tokens_on_crypted_token", unique: true
    t.index ["expires_at"], name: "index_user_refresh_tokens_on_expires_at"
    t.index ["user_id"], name: "index_user_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "name"
    t.string "locale", default: "en", null: false
    t.bigint "current_user_level_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_user_level_id"], name: "index_users_on_current_user_level_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "exercise_submission_files", "exercise_submissions"
  add_foreign_key "exercise_submissions", "user_lessons"
  add_foreign_key "lessons", "levels"
  add_foreign_key "user_jwt_tokens", "users"
  add_foreign_key "user_lessons", "lessons"
  add_foreign_key "user_lessons", "users"
  add_foreign_key "user_levels", "levels"
  add_foreign_key "user_levels", "user_lessons", column: "current_user_lesson_id"
  add_foreign_key "user_levels", "users"
  add_foreign_key "user_refresh_tokens", "users"
  add_foreign_key "users", "user_levels", column: "current_user_level_id"
end
