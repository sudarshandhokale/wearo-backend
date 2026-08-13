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

ActiveRecord::Schema[8.0].define(version: 2026_08_13_100000) do
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
    t.string "fit"
    t.jsonb "usage_tags", default: [], null: false
    t.jsonb "user_usage_tags"
    t.index ["discarded_at"], name: "index_clothing_items_on_discarded_at"
    t.index ["user_id", "category"], name: "index_clothing_items_on_user_id_and_category"
    t.index ["user_id", "fit"], name: "index_clothing_items_on_user_id_and_fit"
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

  create_table "outfit_feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "outfit_id", null: false
    t.string "reaction", null: false
    t.string "reason"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outfit_id"], name: "index_outfit_feedbacks_on_outfit_id"
    t.index ["user_id", "outfit_id"], name: "index_outfit_feedbacks_on_user_id_and_outfit_id", unique: true
    t.index ["user_id"], name: "index_outfit_feedbacks_on_user_id"
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

  create_table "outfit_visualizations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "outfit_id", null: false
    t.string "mode", default: "flat_lay", null: false
    t.string "status", default: "queued", null: false
    t.string "provider"
    t.string "model"
    t.string "response_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "failure_code"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outfit_id", "status"], name: "index_outfit_visualizations_on_outfit_id_and_status"
    t.index ["outfit_id"], name: "index_outfit_visualizations_on_outfit_id"
    t.index ["user_id", "created_at"], name: "index_outfit_visualizations_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_outfit_visualizations_on_user_id"
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
    t.string "name"
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

  create_table "routine_occurrences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "styling_routine_id", null: false
    t.bigint "outfit_id"
    t.datetime "scheduled_for", null: false
    t.string "status", default: "scheduled", null: false
    t.jsonb "context", default: {}, null: false
    t.jsonb "weather_context", default: {}, null: false
    t.jsonb "suggestions", default: [], null: false
    t.string "failure_code"
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outfit_id"], name: "index_routine_occurrences_on_outfit_id"
    t.index ["status", "scheduled_for"], name: "index_routine_occurrences_on_status_and_scheduled_for"
    t.index ["styling_routine_id", "scheduled_for"], name: "index_routine_occurrences_on_routine_and_schedule", unique: true
    t.index ["styling_routine_id"], name: "index_routine_occurrences_on_styling_routine_id"
    t.index ["user_id", "scheduled_for"], name: "index_routine_occurrences_on_user_id_and_scheduled_for"
    t.index ["user_id"], name: "index_routine_occurrences_on_user_id"
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

  create_table "styling_plan_entries", force: :cascade do |t|
    t.bigint "styling_plan_id", null: false
    t.bigint "outfit_id", null: false
    t.date "planned_for", null: false
    t.jsonb "context", default: {}, null: false
    t.jsonb "weather_context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "events_context", default: [], null: false
    t.index ["outfit_id"], name: "index_styling_plan_entries_on_outfit_id"
    t.index ["styling_plan_id", "planned_for"], name: "index_styling_plan_entries_on_styling_plan_id_and_planned_for", unique: true
    t.index ["styling_plan_id"], name: "index_styling_plan_entries_on_styling_plan_id"
  end

  create_table "styling_plans", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "plan_type", null: false
    t.string "status", default: "processing", null: false
    t.string "city"
    t.string "country_code"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.text "prompt"
    t.jsonb "weather_context", default: [], null: false
    t.jsonb "packing_summary", default: {}, null: false
    t.string "failure_code"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "events_context", default: [], null: false
    t.index ["user_id", "start_date"], name: "index_styling_plans_on_user_id_and_start_date"
    t.index ["user_id", "status"], name: "index_styling_plans_on_user_id_and_status"
    t.index ["user_id"], name: "index_styling_plans_on_user_id"
  end

  create_table "styling_routines", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "routine_type", null: false
    t.jsonb "days_of_week", default: [], null: false
    t.time "local_time", null: false
    t.string "usage", null: false
    t.string "occasion"
    t.string "activity"
    t.string "city_mode", default: "profile", null: false
    t.string "city"
    t.string "outfit_strategy", default: "separate", null: false
    t.integer "recommendation_lead_minutes", default: 60, null: false
    t.boolean "reminder_enabled", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "active"], name: "index_styling_routines_on_user_id_and_active"
    t.index ["user_id"], name: "index_styling_routines_on_user_id"
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
    t.datetime "confirmed_at"
    t.datetime "terms_accepted_at"
    t.string "terms_version"
    t.datetime "privacy_accepted_at"
    t.string "privacy_version"
    t.datetime "ai_processing_consent_at"
    t.datetime "adult_confirmed_at"
    t.datetime "full_body_image_consent_at"
    t.integer "token_version", default: 0, null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["confirmed_at"], name: "index_users_on_confirmed_at"
  end

  create_table "wardrobes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", default: "My Wardrobe", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_wardrobes_on_user_id", unique: true
  end

  create_table "wear_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "outfit_id", null: false
    t.date "worn_on", null: false
    t.string "occasion"
    t.jsonb "context", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["outfit_id"], name: "index_wear_histories_on_outfit_id"
    t.index ["user_id", "outfit_id", "worn_on"], name: "index_wear_histories_on_user_id_and_outfit_id_and_worn_on", unique: true
    t.index ["user_id", "worn_on"], name: "index_wear_histories_on_user_id_and_worn_on"
    t.index ["user_id"], name: "index_wear_histories_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_requests", "users"
  add_foreign_key "clothing_items", "users"
  add_foreign_key "clothing_items", "wardrobes"
  add_foreign_key "outfit_feedbacks", "outfits"
  add_foreign_key "outfit_feedbacks", "users"
  add_foreign_key "outfit_items", "clothing_items"
  add_foreign_key "outfit_items", "outfits"
  add_foreign_key "outfit_visualizations", "outfits"
  add_foreign_key "outfit_visualizations", "users"
  add_foreign_key "outfits", "recommendation_requests"
  add_foreign_key "outfits", "users"
  add_foreign_key "recommendation_requests", "users"
  add_foreign_key "routine_occurrences", "outfits"
  add_foreign_key "routine_occurrences", "styling_routines"
  add_foreign_key "routine_occurrences", "users"
  add_foreign_key "style_profiles", "users"
  add_foreign_key "styling_plan_entries", "outfits"
  add_foreign_key "styling_plan_entries", "styling_plans"
  add_foreign_key "styling_plans", "users"
  add_foreign_key "styling_routines", "users"
  add_foreign_key "wardrobes", "users"
  add_foreign_key "wear_histories", "outfits"
  add_foreign_key "wear_histories", "users"
end
