class CreateEqQuotes < ActiveRecord::Migration
  def self.up
    create_table :eq_quotes do |t|
      t.references :stock, index: true, null: false
      t.date :date, index: true, null: false
      t.decimal :open, :high, :low, :close, :previous_close, :original_close, :precision => 8, :scale => 2
      t.decimal :traded_quantity, :precision => 12, :scale => 0
      t.decimal :mov_avg_10d, :mov_avg_50d, :mov_avg_200d, :precision => 8, :scale => 2
    end
    add_foreign_key(:eq_quotes, :stocks)
  end

  def self.down
    drop_table :eq_quotes
  end
end
