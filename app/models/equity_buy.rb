class EquityBuy < EquityTransaction

  has_many :equity_trades
  attr_accessor :holding_qty

  def self.find_holding_quantity stock, date, trading_account, portfolio
    conditions = "stock_id = #{stock.id} and date <= '#{date}' and trading_account_id = #{trading_account.id} and portfolio_id = #{portfolio.id}"
    total_buy_quantity = EquityBuy.where(conditions).sum(:quantity)
    total_sell_quantity = EquitySell.where(conditions).sum(:quantity)
    total_buy_quantity - total_sell_quantity
  end

  def self.find_holdings_on stock, record_date, trading_account, portfolio
    buys = where(stock_id: stock).where("date <= '#{record_date}'").where(trading_account_id: trading_account).where(portfolio_id: portfolio).all
    trades = EquityBuy.find_by_sql "select buy.id, sum(trade.quantity) as sold_qty FROM equity_transactions buy join equity_trades trade on trade.equity_buy_id = buy.id join equity_transactions sell on sell.id = trade.equity_sell_id where buy.stock_id = #{stock.id} and buy.date <= '#{record_date}' and sell.date <= '#{record_date}' group by buy.id"
    sold_quantities = trades.inject({}) {|hash, trade| hash[trade.id] = trade.sold_qty.to_f; hash}
    holdings = []
    buys.each do |buy|
       if (sold_qty = sold_quantities[buy.id]) && ((holding_qty = buy.quantity - sold_qty) > 0 )
         buy.holding_qty = holding_qty
         holdings << buy
       elsif sold_quantities[buy.id].nil?
         buy.holding_qty = buy.quantity
         holdings << buy
       end
    end
    holdings
  end

  #TODO remove record_date, use ex_date
  def apply_face_value_change(conversion_ration, record_date)
    #EQUITYHOLDING SHOULD BE UPDATED :(
    if self.holding_qty.nil? || self.quantity == self.holding_qty
      self.price = self.price * conversion_ration
      self.quantity = self.quantity / conversion_ration
      save!
    else
      EquityBuy.transaction do
        original_quantity = self.quantity
        new_transaction = EquityBuy.new.initialize_dup(self)
        new_transaction.price = self.price * conversion_ration
        new_transaction.quantity = self.holding_qty / conversion_ration
        new_transaction.brokerage = self.brokerage / original_quantity * self.holding_qty
        new_transaction.save!

        self.quantity -= self.holding_qty
        self.brokerage = self.brokerage / original_quantity * self.quantity
        self.save!

        EquityTrade.update_all "equity_buy_id = #{new_transaction.id} from equity_transactions as sell where equity_buy_id = #{self.id} and equity_sell_id = sell.id and sell.date > '#{record_date}'"
      end
    end
  end
end