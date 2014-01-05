class CreateTradingAccounts < ActiveRecord::Migration
  def self.up
    create_table :trading_accounts do |t|
      t.string :name, null: false

      t.timestamps
    end
  end

  def self.down
    drop_table :trading_accounts
  end
end
