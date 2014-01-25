class AlterNseSeriesToIsEquity < ActiveRecord::Migration
  def change
    add_column :stocks, :is_equity, :boolean
    execute("update stocks set is_equity = (nse_series = 'EQ');")
    remove_column :stocks, :nse_series
  end
end
