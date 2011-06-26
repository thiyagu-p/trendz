class CreateStocks < ActiveRecord::Migration
  def self.up
    create_table :stocks do |t|
      t.string :symbol
      t.string :series
      t.date :date
    end
    add_index :stocks, :symbol
  end

  def self.down
    drop_table :stocks
  end
end
