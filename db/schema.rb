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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130204122744) do

  create_table "bonus_actions", :force => true do |t|
    t.integer "stock_id"
    t.date    "ex_date"
    t.integer "holding_qty"
    t.integer "bonus_qty"
  end

  create_table "corporate_action_errors", :force => true do |t|
    t.integer "stock_id"
    t.date    "ex_date"
    t.boolean "is_ignored",   :default => false
    t.string  "full_data"
    t.string  "partial_data"
  end

  create_table "corporate_actions", :force => true do |t|
    t.integer  "stock_id"
    t.date     "ex_date"
    t.string   "parsed_data"
    t.string   "raw_data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "corporate_results", :force => true do |t|
    t.integer  "stock_id"
    t.date     "quarter_end"
    t.decimal  "net_sales",                :precision => 12, :scale => 2
    t.decimal  "net_p_and_l",              :precision => 12, :scale => 2
    t.decimal  "eps_before_extraordinary", :precision => 12, :scale => 2
    t.decimal  "eps",                      :precision => 12, :scale => 2
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dividend_actions", :force => true do |t|
    t.integer "stock_id"
    t.date    "ex_date"
    t.decimal "percentage",               :precision => 6, :scale => 2
    t.string  "nature",     :limit => 10
  end

  create_table "eq_quotes", :force => true do |t|
    t.integer "stock_id"
    t.decimal "open",            :precision => 8,  :scale => 2
    t.decimal "high",            :precision => 8,  :scale => 2
    t.decimal "low",             :precision => 8,  :scale => 2
    t.decimal "close",           :precision => 8,  :scale => 2
    t.decimal "previous_close",  :precision => 8,  :scale => 2
    t.decimal "mov_avg_10d",     :precision => 8,  :scale => 2
    t.decimal "mov_avg_50d",     :precision => 8,  :scale => 2
    t.decimal "mov_avg_200d",    :precision => 8,  :scale => 2
    t.decimal "traded_quantity", :precision => 16, :scale => 2
    t.date    "date"
  end

  add_index "eq_quotes", ["date"], :name => "index_eq_quotes_on_date"
  add_index "eq_quotes", ["stock_id", "date"], :name => "index_eq_quotes_on_stock_id_and_date"
  add_index "eq_quotes", ["stock_id"], :name => "index_eq_quotes_on_stock_id"

  create_table "equity_holdings", :force => true do |t|
    t.integer  "equity_transaction_id", :null => false
    t.integer  "quantity",              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equity_trades", :force => true do |t|
    t.integer  "buy_transaction_id",  :null => false
    t.integer  "sell_transaction_id", :null => false
    t.integer  "quantity",            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equity_transactions", :force => true do |t|
    t.string   "action"
    t.integer  "quantity"
    t.date     "date"
    t.decimal  "price"
    t.decimal  "brokerage"
    t.integer  "trading_account_id"
    t.integer  "portfolio_id"
    t.integer  "stock_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "delivery",           :default => true
  end

  create_table "face_value_actions", :force => true do |t|
    t.integer "stock_id"
    t.date    "ex_date"
    t.integer "from"
    t.integer "to"
  end

  create_table "fo_quotes", :force => true do |t|
    t.integer "stock_id"
    t.decimal "open",                                 :precision => 8,  :scale => 2
    t.decimal "high",                                 :precision => 8,  :scale => 2
    t.decimal "low",                                  :precision => 8,  :scale => 2
    t.decimal "close",                                :precision => 8,  :scale => 2
    t.decimal "strike_price",                         :precision => 8,  :scale => 2
    t.decimal "traded_quantity",                      :precision => 14, :scale => 2
    t.decimal "open_interest",                        :precision => 14, :scale => 2
    t.decimal "change_in_open_interest",              :precision => 10, :scale => 2
    t.date    "date"
    t.date    "expiry_date"
    t.string  "fo_type",                 :limit => 2
    t.string  "expiry_series",           :limit => 7
  end

  add_index "fo_quotes", ["stock_id"], :name => "index_fo_quotes_on_stock_id"

  create_table "market_activities", :force => true do |t|
    t.date    "date",                                                      :null => false
    t.decimal "fii_buy_equity",             :precision => 14, :scale => 2
    t.decimal "fii_sell_equity",            :precision => 14, :scale => 2
    t.decimal "fii_index_futures_buy",      :precision => 14, :scale => 2
    t.decimal "fii_index_futures_sell",     :precision => 14, :scale => 2
    t.decimal "fii_index_options_buy",      :precision => 14, :scale => 2
    t.decimal "fii_index_options_sell",     :precision => 14, :scale => 2
    t.decimal "fii_index_futures_oi",       :precision => 14, :scale => 2
    t.decimal "fii_index_futures_oi_value", :precision => 14, :scale => 2
    t.decimal "fii_index_options_oi",       :precision => 14, :scale => 2
    t.decimal "fii_index_options_oi_value", :precision => 14, :scale => 2
    t.decimal "fii_stock_futures_buy",      :precision => 14, :scale => 2
    t.decimal "fii_stock_futures_sell",     :precision => 14, :scale => 2
    t.decimal "fii_stock_options_buy",      :precision => 14, :scale => 2
    t.decimal "fii_stock_options_sell",     :precision => 14, :scale => 2
    t.decimal "fii_stock_futures_oi",       :precision => 14, :scale => 2
    t.decimal "fii_stock_futures_oi_value", :precision => 14, :scale => 2
    t.decimal "fii_stock_options_oi",       :precision => 14, :scale => 2
    t.decimal "fii_stock_options_oi_value", :precision => 14, :scale => 2
    t.decimal "fii_buy_debit",              :precision => 14, :scale => 2
    t.decimal "fii_sell_debit",             :precision => 14, :scale => 2
  end

  add_index "market_activities", ["date"], :name => "index_market_activities_on_date"

  create_table "portfolios", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "stocks", :force => true do |t|
    t.string  "symbol"
    t.string  "series"
    t.date    "date"
    t.string  "yahoo_code", :limit => 15
    t.integer "face_value",               :default => 10
    t.string  "name"
    t.string  "isin",       :limit => 12
  end

  add_index "stocks", ["symbol"], :name => "index_stocks_on_symbol"

  create_table "stocks_watchlists", :id => false, :force => true do |t|
    t.integer "watchlist_id"
    t.integer "stock_id"
  end

  create_table "trading_accounts", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "watchlists", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "eq_quotes", "stocks", :name => "eq_quotes_stock_id_fk"

end
