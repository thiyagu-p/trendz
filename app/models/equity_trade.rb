class EquityTrade < ActiveRecord::Base

  has_one :buy_transaction, class_name: 'EquityTransaction', primary_key: 'buy_transaction_id', foreign_key: 'id'
  has_one :sell_transaction, class_name: 'EquityTransaction', primary_key: 'sell_transaction_id', foreign_key: 'id'

end