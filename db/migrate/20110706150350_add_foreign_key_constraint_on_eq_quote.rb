class AddForeignKeyConstraintOnEqQuote < ActiveRecord::Migration
  def self.up
    add_foreign_key(:eq_quotes, :stocks)
  end

  def self.down
  end
end
