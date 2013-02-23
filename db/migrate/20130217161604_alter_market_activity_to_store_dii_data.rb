class AlterMarketActivityToStoreDiiData < ActiveRecord::Migration
  def up
    remove_column :market_activities, :fii_buy_debit, :fii_sell_debit
    add_column :market_activities, :dii_buy_equity, :decimal, :precision => 14, :scale => 2
    add_column :market_activities, :dii_sell_equity, :decimal, :precision => 14, :scale => 2

  end

  def down
    remove_column :market_activities, :dii_buy_equity, :dii_sell_equity
    add_column :market_activities, :fii_buy_debit, :decimal, :precision => 14, :scale => 2
    add_column :market_activities, :fii_sell_debit, :decimal, :precision => 14, :scale => 2
  end
end
