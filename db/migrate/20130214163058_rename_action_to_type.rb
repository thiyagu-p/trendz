class RenameActionToType < ActiveRecord::Migration
  def up
    rename_column :equity_transactions, :action, :type
    rename_column :equity_trades, :buy_transaction_id, :equity_buy_id
    rename_column :equity_trades, :sell_transaction_id, :equity_sell_id
    add_column :stocks, :created_at, :datetime
    add_column :stocks, :updated_at, :datetime
  end

  def down
    rename_column :equity_transactions, :type, :action
    rename_column :equity_trades, :equity_buy_id, :buy_transaction_id
    rename_column :equity_trades, :equity_sell_id, :sell_transaction_id
    remove_column :stocks, :created_at, :updated_at
  end
end
