class DividendTransaction < ActiveRecord::Base

  belongs_to :dividend_action
  belongs_to :equity_buy, foreign_key: :equity_transaction_id

end