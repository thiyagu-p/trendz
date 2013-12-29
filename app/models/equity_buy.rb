class EquityBuy < EquityTransaction

  has_many :equity_trades
  attr_accessor :holding_qty

  def self.find_holding_quantity stock, date, trading_account, portfolio
    conditions = "stock_id = #{stock.id} and date <= '#{date}' and trading_account_id = #{trading_account.id} and portfolio_id = #{portfolio.id}"
    total_buy_quantity = EquityBuy.where(conditions).sum(:quantity)
    total_sell_quantity = EquitySell.where(conditions).sum(:quantity)
    total_buy_quantity - total_sell_quantity
  end

  def apply_face_value_change(conversion_ration)
    update_attributes!(price: self.price * conversion_ration, quantity: self.quantity / conversion_ration)
  end

  def partially_sold_on?(date)
    partial_sale? sold_qty_on(date)
  end

  def holding_on?(date)
    date >= self.date && self.quantity > sold_qty_on(date)
  end

  def holding_qty_on(date)
    date >= self.date ? self.quantity - sold_qty_on(date) : 0
  end

  def break_based_on_holding_on(date)
    sold_qty = sold_qty_on(date)
    if partial_sale?(sold_qty)
      holding_qty = self.quantity - sold_qty
      new_transaction = create_transaction_with_quantity(holding_qty)
      update_attributes!(brokerage: self.brokerage / self.quantity * sold_qty, quantity: sold_qty)
      EquityTrade.update_all "equity_buy_id = #{new_transaction.id} from equity_transactions as sell where equity_buy_id = #{self.id} and equity_sell_id = sell.id and sell.date > '#{date}'"
      return new_transaction
    end
  end

  private

  def create_transaction_with_quantity(holding_qty)
    new_transaction = self.dup
    new_transaction.quantity = holding_qty
    new_transaction.brokerage = self.brokerage / self.quantity * holding_qty
    new_transaction.save!
    new_transaction
  end

  def partial_sale?(sold_qty)
    sold_qty != 0 && sold_qty < self.quantity
  end

  def sold_qty_on(date)
    EquityTrade.joins(:equity_sell).where("equity_transactions.date <= '#{date}'").where(equity_buy_id: self.id).sum(:quantity)
  end

end