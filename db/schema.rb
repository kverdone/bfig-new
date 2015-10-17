# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20151017221710) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bookmarks", force: true do |t|
    t.integer  "pick_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "games", force: true do |t|
    t.integer  "week_number"
    t.integer  "home_team_id"
    t.integer  "away_team_id"
    t.integer  "home_team_score"
    t.integer  "away_team_score"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.integer  "season_id"
  end

  create_table "picks", force: true do |t|
    t.integer  "user_id",          null: false
    t.integer  "team_id",          null: false
    t.integer  "week_id",          null: false
    t.text     "why_pick"
    t.text     "comment"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.boolean  "is_second_chance"
    t.integer  "second_team_id"
  end

  add_index "picks", ["user_id"], name: "index_picks_on_user_id", using: :btree

  create_table "seasons", force: true do |t|
    t.integer  "year"
    t.integer  "signup_status"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "teams", force: true do |t|
    t.string   "city"
    t.string   "mascot"
    t.string   "background_color"
    t.string   "text_color"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "short_city_name"
  end

  create_table "user_seasons", force: true do |t|
    t.integer  "user_id"
    t.integer  "season_id"
    t.boolean  "approved"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "full_name",              default: "", null: false
    t.string   "referred_by"
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "is_admin"
    t.integer  "is_veteran"
    t.boolean  "approved"
    t.string   "referral_code"
    t.integer  "referring_user_id"
    t.boolean  "verified"
    t.string   "signup_referral_code"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "weeks", force: true do |t|
    t.integer  "week_number"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "open",        default: false
    t.boolean  "closed",      default: false
    t.integer  "season_id"
  end

end
