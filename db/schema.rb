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

ActiveRecord::Schema[7.1].define(version: 2026_02_15_000002) do
  create_table "groups", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "work_start_slot", null: false
    t.integer "work_end_slot", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shift_details", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "shift_id", null: false
    t.integer "slot_index", null: false
    t.bigint "time_block_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shift_id", "slot_index"], name: "idx_shift_details_shift_slot", unique: true
    t.index ["shift_id"], name: "index_shift_details_on_shift_id"
    t.index ["time_block_id"], name: "index_shift_details_on_time_block_id"
    t.check_constraint "(`slot_index` >= 0) and (`slot_index` <= 95)", name: "chk_shift_details_slot_range"
  end

  create_table "shift_pattern_details", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "shift_pattern_id", null: false
    t.integer "slot_index", null: false
    t.bigint "time_block_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shift_pattern_id", "slot_index"], name: "idx_shift_pattern_details_pattern_slot", unique: true
    t.index ["shift_pattern_id"], name: "index_shift_pattern_details_on_shift_pattern_id"
    t.index ["time_block_id"], name: "index_shift_pattern_details_on_time_block_id"
    t.check_constraint "(`slot_index` >= 0) and (`slot_index` <= 95)", name: "chk_shift_pattern_details_slot_range"
  end

  create_table "shift_patterns", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_shift_patterns_on_group_id"
  end

  create_table "shifts", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.date "work_date", null: false
    t.bigint "shift_pattern_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "work_date"], name: "index_shifts_on_group_id_and_work_date"
    t.index ["group_id"], name: "index_shifts_on_group_id"
    t.index ["shift_pattern_id"], name: "index_shifts_on_shift_pattern_id"
    t.index ["user_id", "work_date"], name: "index_shifts_on_user_id_and_work_date", unique: true
    t.index ["user_id"], name: "index_shifts_on_user_id"
  end

  create_table "staff_time_off_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "target_date", null: false
    t.integer "request_type", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "target_date"], name: "idx_time_off_user_date", unique: true
    t.index ["user_id"], name: "index_staff_time_off_requests_on_user_id"
  end

  create_table "time_blocks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", limit: 191, null: false
    t.string "color_code", null: false
    t.boolean "has_cost", default: true, null: false
    t.boolean "has_sales", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_time_blocks_on_name", unique: true
  end

  create_table "time_off_locks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.date "target_month", null: false
    t.boolean "locked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "target_month"], name: "idx_time_off_lock_group_month", unique: true
    t.index ["group_id"], name: "index_time_off_locks_on_group_id"
  end

  create_table "time_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date", null: false
    t.integer "event_type", null: false
    t.datetime "recorded_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_time_records_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", limit: 191, default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.bigint "group_id"
    t.string "employee_number", limit: 50, null: false
    t.date "joined_on", null: false
    t.date "retired_on"
    t.integer "employment_type", default: 0, null: false
    t.integer "position", default: 2, null: false
    t.integer "salary_type", default: 0, null: false
    t.integer "salary_amount", null: false
    t.string "reset_password_token", limit: 191
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_number"], name: "index_users_on_employee_number", unique: true
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "shift_details", "shifts"
  add_foreign_key "shift_details", "time_blocks"
  add_foreign_key "shift_pattern_details", "shift_patterns"
  add_foreign_key "shift_pattern_details", "time_blocks"
  add_foreign_key "shift_patterns", "groups"
  add_foreign_key "shifts", "groups"
  add_foreign_key "shifts", "shift_patterns"
  add_foreign_key "shifts", "users"
  add_foreign_key "staff_time_off_requests", "users"
  add_foreign_key "time_off_locks", "groups"
  add_foreign_key "time_records", "users"
  add_foreign_key "users", "groups"
end
