class CreateFoQuotes < ActiveRecord::Migration
  def self.up
    create_table :fo_quotes do |t|
      t.references :stock, index: true, null: false
      t.date :date, :expiry_date, null: false
      t.string :fo_type, :limit => 2, null: false
      t.string :expiry_series, :limit => 7, null: false
      t.decimal :open, :high, :low, :close, :strike_price, :precision => 8, :scale => 2
      t.decimal :traded_quantity, :open_interest, :precision => 14, :scale => 2
      t.decimal :change_in_open_interest, :precision => 10, :scale => 2
    end
    add_index :eq_quotes, [:stock_id, :date]
  end

  def self.down
    drop_table :fo_quotes
  end
end
