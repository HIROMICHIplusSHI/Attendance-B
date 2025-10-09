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

ActiveRecord::Schema[7.1].define(version: 2025_10_09_011245) do
  create_table "attendance_change_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "attendance_id", null: false
    t.bigint "requester_id", null: false
    t.bigint "approver_id", null: false
    t.datetime "original_started_at"
    t.datetime "original_finished_at"
    t.datetime "requested_started_at", null: false
    t.datetime "requested_finished_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "change_reason"
    t.index ["approver_id"], name: "index_attendance_change_requests_on_approver_id"
    t.index ["attendance_id"], name: "index_attendance_change_requests_on_attendance_id"
    t.index ["requester_id"], name: "index_attendance_change_requests_on_requester_id"
  end

  create_table "attendances", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "worked_on", null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note", limit: 50
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "worked_on"], name: "index_attendances_on_user_id_and_worked_on", unique: true
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "monthly_approvals", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "approver_id", null: false
    t.date "target_month", null: false
    t.integer "status", default: 0, null: false
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_monthly_approvals_on_approver_id"
    t.index ["user_id", "target_month"], name: "index_monthly_approvals_on_user_id_and_target_month", unique: true
    t.index ["user_id"], name: "index_monthly_approvals_on_user_id"
  end

  create_table "offices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "office_number"
    t.string "name"
    t.string "attendance_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["office_number"], name: "index_offices_on_office_number", unique: true
  end

  create_table "overtime_requests", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "approver_id", null: false
    t.date "worked_on", null: false
    t.datetime "estimated_end_time", null: false
    t.text "business_content", null: false
    t.boolean "next_day_flag", default: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_overtime_requests_on_approver_id"
    t.index ["user_id"], name: "index_overtime_requests_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "basic_time", default: "2025-09-27 23:00:00"
    t.datetime "work_time", default: "2025-09-27 22:30:00"
    t.boolean "admin", default: false
    t.string "department"
    t.string "remember_digest"
    t.bigint "manager_id"
    t.integer "role", default: 0, null: false
    t.string "employee_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["employee_number"], name: "index_users_on_employee_number", unique: true
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "attendance_change_requests", "attendances"
  add_foreign_key "attendance_change_requests", "users", column: "approver_id"
  add_foreign_key "attendance_change_requests", "users", column: "requester_id"
  add_foreign_key "attendances", "users"
  add_foreign_key "monthly_approvals", "users"
  add_foreign_key "monthly_approvals", "users", column: "approver_id"
  add_foreign_key "overtime_requests", "users"
  add_foreign_key "overtime_requests", "users", column: "approver_id"
  add_foreign_key "users", "users", column: "manager_id"
end
