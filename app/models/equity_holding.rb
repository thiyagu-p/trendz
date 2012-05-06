class EquityHolding < ActiveRecord::Base
  belongs_to :equity_transaction

  def self.tradeable_match(transaction)
        self.joins(:equity_transaction).
        where(equity_transactions: { portfolio_id: transaction.portfolio_id,
                                    trading_account_id: transaction.trading_account_id,
                                    stock_id: transaction.stock_id,
                                    delivery: transaction.delivery?,
                                    action: transaction.action == EquityTransaction::BUY ? EquityTransaction::SELL : EquityTransaction::BUY}).
        where("date <= '#{transaction.date}'").
        order("date asc").readonly(false)
  end

end
