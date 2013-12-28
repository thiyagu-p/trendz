class FaceValueTransaction < ActiveRecord::Base
  belongs_to :face_value_action
  belongs_to :equity_buy, foreign_key: :equity_transaction_id
end