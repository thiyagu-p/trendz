class EquityHolding < ActiveRecord::Base
  belongs_to :equity_transaction

  def self.tradeable_match(transaction)
        self.joins(:equity_transaction).
        where(equity_transactions: { portfolio_id: transaction.portfolio_id,
                                    trading_account_id: transaction.trading_account_id,
                                    stock_id: transaction.stock_id,
                                    delivery: transaction.delivery?,
                                    type: transaction.type == EquityTransaction::BUY ? EquityTransaction::SELL : EquityTransaction::BUY}).
        where("date #{date_condition transaction} '#{transaction.date}'").
        order("date asc").readonly(false)
  end

  def self.consolidated
     self.select([:stock_id, :trading_account_id, :portfolio_id, "sum(equity_holdings.quantity) as quantity"]).joins(:equity_transaction)
     .group([:stock_id, :trading_account_id, :portfolio_id])
     .order([:portfolio_id, :stock_id, :quantity, :trading_account_id])
  end

  scope :delivery, lambda { where('delivery') }

  private
  def self.date_condition(transaction)
    transaction.type == EquityTransaction::SELL ? '<=' : '='
  end

end
