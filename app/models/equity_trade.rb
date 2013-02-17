class EquityTrade < ActiveRecord::Base

  belongs_to :equity_buy
  belongs_to :equity_sell

end