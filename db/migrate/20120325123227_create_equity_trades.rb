class CreateEquityTrades < ActiveRecord::Migration
  def self.up
    create_table :equity_trades do |t|
      t.integer :buy_transaction_id, null: false
      t.integer :sell_transaction_id, null: false
      t.integer :quantity, null: false
      t.timestamps
    end

    create_table :equity_holdings do |t|
      t.references :equity_transaction, null: false
      t.integer :quantity, null: false
      t.timestamps
    end

    add_column :equity_transactions, :delivery, :boolean, default: true
  end

  def self.down
    drop_table :equity_trades
    drop_table :equity_holdings
    remove_column :equity_transactions, :delivery
  end
end
