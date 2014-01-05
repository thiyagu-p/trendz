class AddDividendTransaction < ActiveRecord::Migration
  def change
    create_join_table :equity_transaction, :dividend_action, table_name: :dividend_transactions do |t|
      t.decimal :value, precision: 7, scale: 2, null: false
    end
    add_foreign_key(:dividend_transactions, :equity_transactions)
    add_foreign_key(:dividend_transactions, :dividend_actions)

    add_index :dividend_transactions, [:dividend_action_id, :equity_transaction_id], unique: true, name: :idx_dividend_transaction
  end
end
