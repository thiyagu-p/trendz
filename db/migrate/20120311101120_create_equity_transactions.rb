class CreateEquityTransactions < ActiveRecord::Migration
  def self.up
    create_table :equity_transactions do |t|
      t.string :action, length: 5
      t.integer :quantity
      t.date :date
      t.decimal :price
      t.decimal :brokerage
      t.references :trading_account
      t.references :portfolio
      t.references :stock
      t.timestamps
    end
  end

  def self.down
    drop_table :equity_transactions
  end
end
