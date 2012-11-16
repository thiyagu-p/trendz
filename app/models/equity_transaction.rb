class EquityTransaction < ActiveRecord::Base

  BUY = 'buy'
  SELL = 'sell'

  belongs_to :portfolio
  belongs_to :trading_account
  belongs_to :stock

  validates_presence_of :price, :portfolio, :trading_account, :stock, :date
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :action, in: [BUY, SELL]

  def buy?
    action == BUY
  end


  def self.find_holding_quantity stock, date, trading_account, portfolio
    query = where(stock_id: stock).where("date <= '#{date}'").where(trading_account_id: trading_account).where(portfolio_id: portfolio)
    total_buy_quantity = query.where(action: BUY).sum(:quantity)
    total_sell_quantity = query.where(action: SELL).sum(:quantity)
    total_buy_quantity - total_sell_quantity
  end

end
