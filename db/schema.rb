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

ActiveRecord::Schema[8.1].define(version: 2026_11_08_120000) do
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

  create_table "podcast_episodes", force: :cascade do |t|
    t.integer "podcast_id", null: false
    t.string "slug", null: false
    t.integer "number"
    t.string "title", null: false
    t.text "summary"
    t.text "show_notes"
    t.text "transcript"
    t.string "youtube_url"
    t.datetime "published_at"
    t.integer "duration_seconds"
    t.boolean "explicit", default: false, null: false
    t.boolean "published", default: false, null: false
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["podcast_id", "published", "published_at"], name: "idx_on_podcast_id_published_published_at_d51652709c"
    t.index ["podcast_id", "slug"], name: "index_podcast_episodes_on_podcast_id_and_slug", unique: true
    t.index ["podcast_id"], name: "index_podcast_episodes_on_podcast_id"
  end

  create_table "podcasts", force: :cascade do |t|
    t.string "slug", null: false
    t.string "title", null: false
    t.string "tagline"
    t.text "description"
    t.string "author"
    t.string "owner_email"
    t.string "language", default: "de", null: false
    t.string "category", default: "Technology", null: false
    t.boolean "explicit", default: false, null: false
    t.boolean "published", default: false, null: false
    t.integer "position"
    t.string "youtube_url"
    t.string "spotify_url"
    t.string "apple_url"
    t.string "accent_color"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published", "position"], name: "index_podcasts_on_published_and_position"
    t.index ["slug"], name: "index_podcasts_on_slug", unique: true
  end

  create_table "project_downloads", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "label"
    t.string "url", null: false
    t.string "version"
    t.string "file_type"
    t.string "architecture"
    t.bigint "byte_size"
    t.boolean "featured", default: false, null: false
    t.integer "position"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_downloads_on_project_id"
  end

  create_table "project_features", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "title", null: false
    t.text "body"
    t.integer "position"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_features_on_project_id"
  end

  create_table "project_links", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "label", null: false
    t.string "url", null: false
    t.string "display_url"
    t.integer "position"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_links_on_project_id"
  end

  create_table "project_relations", force: :cascade do |t|
    t.integer "project_id", null: false
    t.integer "related_project_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "related_project_id"], name: "index_project_relations_on_project_id_and_related_project_id", unique: true
    t.index ["project_id"], name: "index_project_relations_on_project_id"
    t.index ["related_project_id"], name: "index_project_relations_on_related_project_id"
  end

  create_table "project_screenshots", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "caption"
    t.string "video_url"
    t.boolean "hero", default: false, null: false
    t.integer "position"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_project_screenshots_on_project_id"
  end

  create_table "project_updates", force: :cascade do |t|
    t.integer "project_id", null: false
    t.string "version"
    t.string "title", null: false
    t.text "body"
    t.date "released_on"
    t.string "state", default: "released", null: false
    t.string "url"
    t.bigint "github_release_id"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "github_release_id"], name: "index_project_updates_on_github_release", unique: true, where: "github_release_id IS NOT NULL"
    t.index ["project_id"], name: "index_project_updates_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "slug", null: false
    t.string "name", null: false
    t.string "tagline"
    t.text "description"
    t.string "kind", null: false
    t.string "status", default: "active", null: false
    t.string "platforms"
    t.string "tech_stack"
    t.string "price"
    t.string "license"
    t.string "formats"
    t.boolean "published", default: false, null: false
    t.boolean "featured", default: false, null: false
    t.integer "featured_position"
    t.integer "position"
    t.datetime "last_activity_at"
    t.string "homepage_url"
    t.string "source_url"
    t.string "github_repo"
    t.datetime "github_synced_at"
    t.string "github_sync_error"
    t.integer "github_stars"
    t.json "locked_fields", default: [], null: false
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["github_repo"], name: "index_projects_on_github_repo", unique: true, where: "github_repo IS NOT NULL"
    t.index ["published", "featured", "featured_position"], name: "index_projects_on_published_and_featured_and_featured_position"
    t.index ["published", "last_activity_at"], name: "index_projects_on_published_and_last_activity_at"
    t.index ["slug"], name: "index_projects_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "site_profiles", force: :cascade do |t|
    t.string "terminal_prompt"
    t.string "hero_headline"
    t.text "hero_intro"
    t.string "about_headline"
    t.text "about_body"
    t.string "skills"
    t.string "accent_color", default: "#D4F25A", null: false
    t.text "imprint_body"
    t.text "privacy_body"
    t.json "translations", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "podcast_episodes", "podcasts"
  add_foreign_key "project_downloads", "projects"
  add_foreign_key "project_features", "projects"
  add_foreign_key "project_links", "projects"
  add_foreign_key "project_relations", "projects"
  add_foreign_key "project_relations", "projects", column: "related_project_id"
  add_foreign_key "project_screenshots", "projects"
  add_foreign_key "project_updates", "projects"
  add_foreign_key "sessions", "users"
end
