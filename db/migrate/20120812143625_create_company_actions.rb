class CreateCompanyActions < ActiveRecord::Migration
  def self.up
    create_table :corporate_actions do |t|
      t.references :stock
      t.date :ex_date
      t.string :parsed_data
      t.string :raw_data
      t.timestamps
    end
  end

  def self.down
    drop_table :corporate_actions
  end
end
