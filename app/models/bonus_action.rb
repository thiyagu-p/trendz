class BonusAction < ActiveRecord::Base
  belongs_to :stock
  has_many :bonus_transactions
  has_many :equity_transactions, through: :bonus_transactions, source: :equity_buy

  def apply
    return if applied?
    self.transaction do
      apply_on_portfolio
      apply_on_quote
      self.applied = true
      save!
    end
  end

  private

  def apply_on_quote
    factor = self.holding_qty.to_f / (self.holding_qty + self.bonus_qty).to_f
    EqQuote.apply_factor self.stock, factor, ex_date
    FoQuote.apply_factor self.stock, factor, ex_date
  end

  def apply_on_portfolio
    TradingAccount.all.each do |trading_account|
      Portfolio.all.each do |portfolio|
        record_date = self.ex_date - 1
        holding_qty = EquityBuy.find_holding_quantity self.stock, record_date, trading_account, portfolio
        bonus_qty = holding_qty / self.holding_qty * self.bonus_qty
        if bonus_qty > 0
          eq_transaction = EquityBuy.create!(stock: self.stock, date: self.ex_date, trading_account: trading_account, portfolio: portfolio,
                            quantity: bonus_qty, price: 0, brokerage: 0)
          self.equity_transactions << eq_transaction
          EquityHolding.create(equity_transaction: eq_transaction, quantity: bonus_qty)
        end
      end
    end
  end
end
