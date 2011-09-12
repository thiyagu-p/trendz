class CreateMarketActivities < ActiveRecord::Migration
  def self.up
    create_table :market_activities do |t|
      t.date :date, :date, :unique => true, :null => false
      t.decimal :fii_buy_equity, :dii_buy_equity, :fii_sell_equity, :dii_sell_equity, :precision => 14, :scale => 2
      t.decimal :fii_index_futures_buy, :fii_index_futures_sell, :fii_index_options_buy, :fii_index_options_sell, :precision => 14, :scale => 2
      t.decimal :fii_index_futures_oi, :fii_index_futures_oi_value, :fii_index_options_oi, :fii_index_options_oi_value, :precision => 14, :scale => 2
      t.decimal :fii_stock_futures_buy, :fii_stock_futures_sell, :fii_stock_options_buy, :fii_stock_options_sell, :precision => 14, :scale => 2
      t.decimal :fii_stock_futures_oi, :fii_stock_futures_oi_value, :fii_stock_options_oi, :fii_stock_options_oi_value, :precision => 14, :scale => 2
    end
    add_index :market_activities, :date
  end

  def self.down
    drop_table :market_activities
  end
end
