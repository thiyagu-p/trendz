class CreateWatchlists < ActiveRecord::Migration
  def self.up
    create_table :watchlists do |t|
      t.string :name
      t.timestamps
    end

    create_table :stocks_watchlists, id: false do |t|
      t.references :watchlist, :stock
    end
  end

  def self.down
    drop_table :watchlists
    drop_table :stocks_watchlists
  end
end
