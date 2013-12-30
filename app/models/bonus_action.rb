class BonusAction < ActiveRecord::Base
  belongs_to :stock
  has_many :bonus_transactions
  has_many :bonus, through: :bonus_transactions, class_name: EquityBuy

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
        buys = EquityBuy.where(stock_id: self.stock.id, trading_account_id: trading_account.id, portfolio_id: portfolio.id).where("date < '#{ex_date}'").to_a
        bonus_issued_ids = BonusTransaction.where(bonus_action_id: self.id, source_transaction_id: buys.collect(&:id)).to_a.collect(&:source_transaction_id)
        bonusable_buys = buys.reject{|buy| !buy.holding_on?(record_date)}.reject{|buy| bonus_issued_ids.include? buy.id}

        holding_qty = bonusable_buys.sum{|buy| buy.holding_qty_on(record_date)}
        bonus_qty = holding_qty / self.holding_qty * self.bonus_qty
        if bonus_qty > 0
          eq_transaction = EquityBuy.create!(stock: self.stock, date: self.ex_date, trading_account: trading_account, portfolio: portfolio,
                            quantity: bonus_qty, price: 0, brokerage: 0)
          bonusable_buys.each do |buy|
            self.bonus_transactions << BonusTransaction.new(bonus: eq_transaction, source_transaction: buy)
          end
          EquityHolding.create(equity_transaction: eq_transaction, quantity: bonus_qty)
        end
      end
    end
  end
end
