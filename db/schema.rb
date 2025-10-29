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

ActiveRecord::Schema[8.1].define(version: 2025_10_29_055355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "concepts", force: :cascade do |t|
    t.text "content_html", null: false
    t.text "content_markdown", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "premium_video_id"
    t.string "premium_video_provider"
    t.string "slug", null: false
    t.string "standard_video_id"
    t.string "standard_video_provider"
    t.string "title", null: false
    t.bigint "unlocked_by_lesson_id"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_concepts_on_slug", unique: true
    t.index ["unlocked_by_lesson_id"], name: "index_concepts_on_unlocked_by_lesson_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.text "body_mjml", null: false
    t.text "body_text", null: false
    t.datetime "created_at", null: false
    t.string "locale", null: false
    t.string "slug"
    t.text "subject", null: false
    t.integer "type", null: false
    t.datetime "updated_at", null: false
    t.index ["type", "slug", "locale"], name: "index_email_templates_on_type_and_slug_and_locale", unique: true
  end

  create_table "exercise_submission_files", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "digest", null: false
    t.bigint "exercise_submission_id", null: false
    t.string "filename", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_submission_id"], name: "index_exercise_submission_files_on_exercise_submission_id"
  end

  create_table "exercise_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_lesson_id", null: false
    t.string "uuid", null: false
    t.index ["user_lesson_id"], name: "index_exercise_submissions_on_user_lesson_id"
    t.index ["uuid"], name: "index_exercise_submissions_on_uuid", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.datetime "created_at"
    t.string "scope"
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "lessons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "data", default: {}, null: false
    t.text "description", null: false
    t.bigint "level_id", null: false
    t.integer "position", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id", "position"], name: "index_lessons_on_level_id_and_position", unique: true
    t.index ["level_id"], name: "index_lessons_on_level_id"
    t.index ["slug"], name: "index_lessons_on_slug", unique: true
    t.index ["type"], name: "index_lessons_on_type"
  end

  create_table "levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.integer "position", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_levels_on_position", unique: true
    t.index ["slug"], name: "index_levels_on_slug", unique: true
  end

  create_table "user_data", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "unlocked_concept_ids", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["unlocked_concept_ids"], name: "index_user_data_on_unlocked_concept_ids", using: :gin
    t.index ["user_id"], name: "index_user_data_on_user_id", unique: true
  end

  create_table "user_lessons", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "lesson_id", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["lesson_id"], name: "index_user_lessons_on_lesson_id"
    t.index ["user_id", "lesson_id"], name: "index_user_lessons_on_user_id_and_lesson_id", unique: true
    t.index ["user_id"], name: "index_user_lessons_on_user_id"
  end

  create_table "user_levels", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "current_user_lesson_id"
    t.integer "email_status", default: 0, null: false
    t.bigint "level_id", null: false
    t.datetime "started_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["current_user_lesson_id"], name: "index_user_levels_on_current_user_lesson_id"
    t.index ["level_id"], name: "index_user_levels_on_level_id"
    t.index ["user_id", "level_id"], name: "index_user_levels_on_user_id_and_level_id", unique: true
    t.index ["user_id"], name: "index_user_levels_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "current_user_level_id"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti", null: false
    t.string "locale", default: "en", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["current_user_level_id"], name: "index_users_on_current_user_level_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "video_production_nodes", force: :cascade do |t|
    t.jsonb "asset"
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "inputs", default: {}, null: false
    t.boolean "is_valid", default: false, null: false
    t.jsonb "metadata"
    t.jsonb "output"
    t.bigint "pipeline_id", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.jsonb "validation_errors", default: {}, null: false
    t.index ["pipeline_id", "status"], name: "index_video_production_nodes_on_pipeline_id_and_status"
    t.index ["pipeline_id"], name: "index_video_production_nodes_on_pipeline_id"
    t.index ["status"], name: "index_video_production_nodes_on_status"
    t.index ["type"], name: "index_video_production_nodes_on_type"
    t.index ["uuid"], name: "index_video_production_nodes_on_uuid", unique: true
  end

  create_table "video_production_pipelines", force: :cascade do |t|
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.string "version", default: "1.0", null: false
    t.index ["updated_at"], name: "index_video_production_pipelines_on_updated_at"
    t.index ["uuid"], name: "index_video_production_pipelines_on_uuid", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "concepts", "lessons", column: "unlocked_by_lesson_id"
  add_foreign_key "exercise_submission_files", "exercise_submissions"
  add_foreign_key "exercise_submissions", "user_lessons"
  add_foreign_key "lessons", "levels"
  add_foreign_key "user_data", "users"
  add_foreign_key "user_lessons", "lessons"
  add_foreign_key "user_lessons", "users"
  add_foreign_key "user_levels", "levels"
  add_foreign_key "user_levels", "user_lessons", column: "current_user_lesson_id"
  add_foreign_key "user_levels", "users"
  add_foreign_key "users", "user_levels", column: "current_user_level_id"
  add_foreign_key "video_production_nodes", "video_production_pipelines", column: "pipeline_id", on_delete: :cascade
end
