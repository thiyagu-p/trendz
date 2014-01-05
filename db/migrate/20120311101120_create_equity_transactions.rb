class CreateEquityTransactions < ActiveRecord::Migration
  def self.up
    create_table :equity_transactions do |t|
      t.string :action, length: 5, null: false
      t.integer :quantity, null: false
      t.date :date, null: false
      t.decimal :price, precision: 7, scale: 2, null: false
      t.decimal :brokerage, precision: 7, scale: 2, default: 0
      t.references :trading_account, null: false
      t.references :portfolio, null: false
      t.references :stock, index: true, null: false
      t.timestamps
    end
  end

  def self.down
    drop_table :equity_transactions
  end
end
