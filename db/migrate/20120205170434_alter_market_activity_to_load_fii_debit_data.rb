class AlterMarketActivityToLoadFiiDebitData < ActiveRecord::Migration
  def self.up
    MarketActivity.delete_all
    remove_column :market_activities, :dii_buy_equity, :dii_sell_equity
    add_column :market_activities, :fii_buy_debit, :decimal, :precision => 14, :scale => 2
    add_column :market_activities, :fii_sell_debit, :decimal, :precision => 14, :scale => 2
  end
end
