class AddYahooCodeToStocks < ActiveRecord::Migration
  def self.up
    add_column :stocks, :yahoo_code, :string, limit: 15
  end

  def self.down
    remove_column :stocks, :yahoo_code
  end
end
