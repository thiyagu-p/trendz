class IncreaseDividendPercentagePrecision < ActiveRecord::Migration
  def change
    change_column :dividend_actions, :percentage, :decimal, :precision => 8, :scale => 2
  end
end
