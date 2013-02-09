class AddBseDetailsToStockMaster < ActiveRecord::Migration
  def self.up
    add_column :stocks, :bse_code, :integer
    add_column :stocks, :bse_symbol, :string, limit: 15
    add_column :stocks, :bse_group, :string, limit: 3
    add_column :stocks, :bse_active, :boolean, default: false
    add_column :stocks, :nse_active, :boolean, default: false
    add_column :stocks, :industry, :string
    rename_column :stocks, :series, :nse_series
  end

  def self.down
    remove_column :stocks, :industry, :bse_code, :bse_symbol, :bse_group, :bse_active, :nse_active
    rename_column :stocks, :nse_series, :series
  end
end
