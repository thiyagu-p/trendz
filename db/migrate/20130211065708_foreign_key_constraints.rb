class ForeignKeyConstraints < ActiveRecord::Migration
  def up
    add_foreign_key(:bonus_actions, :stocks)
    add_foreign_key(:corporate_action_errors, :stocks)
    add_foreign_key(:corporate_results, :stocks)
    add_foreign_key(:dividend_actions, :stocks)
    add_foreign_key(:face_value_actions, :stocks)
    add_foreign_key(:fo_quotes, :stocks)
    add_foreign_key(:stocks_watchlists, :stocks)
    add_foreign_key(:stocks_watchlists, :watchlists)
    add_foreign_key(:equity_transactions, :stocks)
    add_foreign_key(:equity_transactions, :trading_accounts)
    add_foreign_key(:equity_transactions, :portfolios)
    add_foreign_key(:equity_holdings, :equity_transactions)
    add_foreign_key(:equity_trades, :equity_transactions, column: :buy_transaction_id)
    add_foreign_key(:equity_trades, :equity_transactions, column: :sell_transaction_id)
  end

  def down
  end
end
