class BonusTransaction < ActiveRecord::Base
  belongs_to :bonus_action
  belongs_to :equity_buy, foreign_key: :equity_transaction_id
end