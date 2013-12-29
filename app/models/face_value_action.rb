class FaceValueAction < ActiveRecord::Base
  belongs_to :stock
  has_many :face_value_transactions
  has_many :equity_transactions, through: :face_value_transactions, source: :equity_buy

  def apply
    return if applied?
    self.transaction do
      apply_on_portfolio
      apply_on_quotes
      update_attribute(:applied, true)
    end
  end

  private

  def apply_on_quotes
    EqQuote.apply_factor self.stock, conversion_ration, ex_date
    FoQuote.apply_factor self.stock, conversion_ration, ex_date
  end

  def conversion_ration
    (to.to_f/from.to_f).round(2)
  end

  def apply_on_portfolio

    buys = EquityBuy.where(stock_id: self.stock_id).where("date < '#{ex_date}'")
    buys.each do |buy|
      record_date = ex_date-1
      next unless buy.holding_on?(record_date)
      if buy.partially_sold_on?(record_date)
        new_transaction = buy.break_based_on_holding_on(record_date)
        new_transaction.apply_face_value_change(conversion_ration)
        self.equity_transactions << new_transaction
        sold_quantity = EquityTrade.where(equity_buy_id: new_transaction.id).sum(:quantity)
        EquityHolding.create!(equity_transaction_id: new_transaction.id, quantity: new_transaction.quantity - sold_quantity)
        EquityHolding.find_by(equity_transaction_id: buy.id).destroy
      else
        buy.apply_face_value_change(conversion_ration)
        self.equity_transactions << buy
        holding = EquityHolding.find_by(equity_transaction_id: buy.id)
        if holding
          sold_quantity = EquityTrade.where(equity_buy_id: buy.id).sum(:quantity)
          holding.update_attribute(:quantity, buy.quantity - sold_quantity)
        end
      end
    end
  end
end
