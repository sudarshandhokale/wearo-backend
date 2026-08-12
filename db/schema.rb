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

ActiveRecord::Schema[8.0].define(version: 2026_08_12_140100) do
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

  create_table "ai_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "trackable_type"
    t.bigint "trackable_id"
    t.string "operation", null: false
    t.string "status", default: "pending", null: false
    t.string "provider"
    t.string "model"
    t.string "response_id"
    t.integer "reserved_tokens", default: 0, null: false
    t.integer "input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.integer "attempt_count", default: 0, null: false
    t.string "failure_code"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["response_id"], name: "index_ai_requests_on_response_id", unique: true, where: "(response_id IS NOT NULL)"
    t.index ["trackable_type", "trackable_id"], name: "index_ai_requests_on_trackable"
    t.index ["user_id", "created_at"], name: "index_ai_requests_on_user_id_and_created_at"
    t.index ["user_id", "status", "created_at"], name: "index_ai_requests_on_user_id_and_status_and_created_at"
    t.index ["user_id"], name: "index_ai_requests_on_user_id"
  end

  create_table "clothing_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "wardrobe_id", null: false
    t.string "name"
    t.string "category"
    t.string "subcategory"
    t.string "primary_color"
    t.jsonb "secondary_colors", default: [], null: false
    t.string "pattern"
    t.string "material"
    t.jsonb "season_tags", default: [], null: false
    t.jsonb "occasion_tags", default: [], null: false
    t.jsonb "style_tags", default: [], null: false
    t.integer "formality_score"
    t.string "status", default: "uploaded", null: false
    t.jsonb "ai_metadata", default: {}, null: false
    t.datetime "ai_analyzed_at"
    t.datetime "discarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_checksum"
    t.string "garment_type"
    t.jsonb "cultural_tags", default: [], null: false
    t.index ["discarded_at"], name: "index_clothing_items_on_discarded_at"
    t.index ["user_id", "category"], name: "index_clothing_items_on_user_id_and_category"
    t.index ["user_id", "garment_type"], name: "index_clothing_items_on_user_id_and_garment_type"
    t.index ["user_id", "image_checksum"], name: "index_active_clothing_items_on_user_and_image_checksum", unique: true, where: "((discarded_at IS NULL) AND (image_checksum IS NOT NULL))"
    t.index ["user_id", "primary_color"], name: "index_clothing_items_on_user_id_and_primary_color"
    t.index ["user_id", "status"], name: "index_clothing_items_on_user_id_and_status"
    t.index ["user_id"], name: "index_clothing_items_on_user_id"
    t.index ["wardrobe_id"], name: "index_clothing_items_on_wardrobe_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exp"], name: "index_jwt_denylist_on_exp"
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "outfit_items", force: :cascade do |t|
    t.bigint "outfit_id", null: false
    t.bigint "clothing_item_id", null: false
    t.string "role", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clothing_item_id"], name: "index_outfit_items_on_clothing_item_id"
    t.index ["outfit_id", "clothing_item_id"], name: "index_outfit_items_on_outfit_id_and_clothing_item_id", unique: true
    t.index ["outfit_id", "position"], name: "index_outfit_items_on_outfit_id_and_position", unique: true
    t.index ["outfit_id"], name: "index_outfit_items_on_outfit_id"
  end

  create_table "outfits", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "prompt"
    t.string "occasion"
    t.jsonb "context", default: {}, null: false
    t.jsonb "weather_context", default: {}, null: false
    t.decimal "recommendation_score", precision: 5, scale: 2
    t.text "explanation"
    t.string "status", default: "recommended", null: false
    t.datetime "recommended_for"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recommendation_request_id"
    t.jsonb "score_breakdown", default: {}, null: false
    t.integer "rating"
    t.string "feedback_note"
    t.datetime "status_updated_at"
    t.index ["recommendation_request_id"], name: "index_outfits_on_recommendation_request_id"
    t.index ["recommended_for"], name: "index_outfits_on_recommended_for"
    t.index ["user_id", "created_at"], name: "index_outfits_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_outfits_on_user_id_and_status"
    t.index ["user_id"], name: "index_outfits_on_user_id"
  end

  create_table "recommendation_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "prompt", null: false
    t.jsonb "context", default: {}, null: false
    t.jsonb "wardrobe_suggestions", default: [], null: false
    t.string "status", default: "processing", null: false
    t.string "ranking_source"
    t.string "provider"
    t.string "model"
    t.string "response_id"
    t.integer "input_tokens", default: 0, null: false
    t.integer "output_tokens", default: 0, null: false
    t.integer "total_tokens", default: 0, null: false
    t.integer "attempt_count", default: 0, null: false
    t.string "failure_code"
    t.datetime "recommended_for"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "created_at"], name: "index_recommendation_requests_on_user_id_and_created_at"
    t.index ["user_id", "status"], name: "index_recommendation_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_recommendation_requests_on_user_id"
  end

  create_table "style_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "preferred_styles", default: [], null: false
    t.jsonb "preferred_colors", default: [], null: false
    t.jsonb "disliked_colors", default: [], null: false
    t.jsonb "fit_preferences", default: {}, null: false
    t.jsonb "additional_preferences", default: {}, null: false
    t.boolean "onboarding_completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_style_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name"
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "country_code", default: "US", null: false
    t.string "preferred_city"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  create_table "wardrobes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "My Wardrobe", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wardrobes_on_user_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_requests", "users"
  add_foreign_key "clothing_items", "users"
  add_foreign_key "clothing_items", "wardrobes"
  add_foreign_key "outfit_items", "clothing_items"
  add_foreign_key "outfit_items", "outfits"
  add_foreign_key "outfits", "recommendation_requests"
  add_foreign_key "outfits", "users"
  add_foreign_key "recommendation_requests", "users"
  add_foreign_key "style_profiles", "users"
  add_foreign_key "wardrobes", "users"
end
