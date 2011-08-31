class CreateEqQuotes < ActiveRecord::Migration
  def self.up
    create_table :eq_quotes do |t|
      t.references :stock
      t.decimal :open, :high, :low, :close, :previous_close, :precision => 8, :scale => 2
      t.decimal :mov_avg_10d, :mov_avg_50d, :mov_avg_200d, :precision => 8, :scale => 2
      t.decimal :traded_quantity, :precision => 16, :scale => 2
      t.date :date
    end
    add_index :eq_quotes, :stock_id
    add_index :eq_quotes, :date
  end

  def self.down
    drop_table :eq_quotes
  end
end
