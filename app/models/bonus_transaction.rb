class BonusTransaction < ActiveRecord::Base
  belongs_to :bonus_action
  belongs_to :source_transaction, foreign_key: :source_transaction_id, class_name: EquityBuy
  belongs_to :bonus, foreign_key: :bonus_id, class_name: EquityBuy
end