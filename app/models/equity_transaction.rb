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
end
