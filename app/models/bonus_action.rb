class BonusAction < ActiveRecord::Base
  belongs_to :stock

  def apply
    return if applied?
    self.transaction do
      apply_on_portfolio
      apply_on_transaction
      self.applied = true
      save!
    end
  end

  private

  def apply_on_transaction
    factor = self.holding_qty.to_f / (self.holding_qty + self.bonus_qty).to_f
    EqQuote.apply_factor(self.stock, factor, self.ex_date)
    FoQuote.apply_factor(self.stock, factor, self.ex_date)
  end

  def apply_on_portfolio
    TradingAccount.all.each do |trading_account|
      Portfolio.all.each do |portfolio|
        record_date = self.ex_date - 1
        holding_qty = EquityBuy.find_holding_quantity self.stock, record_date, trading_account, portfolio
        bonus_qty = holding_qty / self.holding_qty * self.bonus_qty
        EquityBuy.create!(stock: self.stock, date: self.ex_date, trading_account: trading_account, portfolio: portfolio,
                          quantity: bonus_qty, price: 0, brokerage: 0) if bonus_qty > 0
      end
    end
  end
end
