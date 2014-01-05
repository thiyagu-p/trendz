class CreateImportStatuses < ActiveRecord::Migration
  def change
    create_table :import_statuses do |t|
      t.string :source, null: false
      t.date :data_upto
      t.date :last_run
      t.boolean :completed
    end
  end
end
