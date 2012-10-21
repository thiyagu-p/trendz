class CreateCorporateResults < ActiveRecord::Migration
  def self.up
    create_table :corporate_results do |t|
      t.references :stock
      t.date :quarter_end
      t.decimal :net_sales, :net_p_and_l, :eps_before_extraordinary, :eps, :precision => 12, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :corporate_results
  end
end
