ActiveRecord::Schema[7.0].define(version: 2021_06_24_163732) do

  enable_extension "plpgsql"
  enable_extension "pgcrypto"
  enable_extension "unaccent"
  enable_extension "uuid-ossp"

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

end
