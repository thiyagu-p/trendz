class EquityTransaction < ActiveRecord::Base

  BUY = 'EquityBuy'
  SELL = 'EquitySell'

  belongs_to :portfolio
  belongs_to :trading_account
  belongs_to :stock

  validates_presence_of :price, :portfolio, :trading_account, :stock, :date
  validates_numericality_of :quantity, greater_than: 0
  validates_inclusion_of :type, in: [BUY, SELL]

end
