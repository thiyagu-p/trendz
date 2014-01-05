class CreateDividends < ActiveRecord::Migration
  def self.up

    add_column :stocks, :face_value, :integer, default: 10

    create_table :dividend_actions do |t|
      t.references :stock
      t.date :ex_date
      t.decimal :percentage, :precision => 6, :scale => 2
      t.decimal :value, :precision => 6, :scale => 2
      t.string :nature, limit: 10
    end

    create_table :face_value_actions do |t|
      t.references :stock
      t.date :ex_date
      t.integer :from, :to
    end

    create_table :bonus_actions do |t|
      t.references :stock
      t.date :ex_date
      t.integer :holding_qty, :bonus_qty
    end

    create_table :corporate_action_errors do |t|
      t.references :stock
      t.date :ex_date
      t.boolean :is_ignored, :default => false
      t.string :full_data, :partial_data
    end
  end

  def self.down
    remove_column :stocks, :face_value
    drop_table :dividend_actions
    drop_table :face_value_actions
    drop_table :bonus_actions
    drop_table :corporate_action_errors
  end
end
