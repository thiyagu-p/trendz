class CreateFoQuotes < ActiveRecord::Migration
  def self.up
    create_table :fo_quotes do |t|
      t.references :stock
      t.decimal :open, :high, :low, :close, :strike_price, :precision => 8, :scale => 2
      t.decimal :traded_quantity, :open_interest, :change_in_open_interest, :precision => 10, :scale => 2
      t.date :date, :expiry_date
      t.string :fo_type, :limit => 2
      t.string :expiry_series, :limit => 7
    end
    add_index :fo_quotes, :stock_id
  end

  def self.down
    drop_table :fo_quotes
  end
end
