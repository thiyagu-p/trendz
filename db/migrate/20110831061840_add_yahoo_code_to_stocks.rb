class AddYahooCodeToStocks < ActiveRecord::Migration
  def self.up
    add_column :stocks, :yahoo_code, :string, limit: 15
    {'BANKNIFTY' => '^NSEBANK',
    'CNXIT' => '^CNXIT',
    'NIFTY' => '^NSEI',
    'NFTYMCAP50' => '^CRSMID',
    'DJIA' => '^DJI',
    'S&P500' => '^GSPC'}.each_pair do |symbol, yahoo_code|
      stock = Stock.find_by_symbol(symbol)
      stock.update_attribute(:yahoo_code, yahoo_code) if stock
    end
  end

  def self.down
    remove_column :stocks, :yahoo_code
  end
end
