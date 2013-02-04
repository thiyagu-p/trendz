class AddCompanyName < ActiveRecord::Migration
  def self.up
    add_column :stocks, :name, :string
    add_column :stocks, :isin, :string, limit: 12

  end

  def self.down
    remove_column :stocks, :name
    remove_column :stocks, :isin
  end
end
