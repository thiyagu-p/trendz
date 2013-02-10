class CreateImportStatuses < ActiveRecord::Migration
  def change
    create_table :import_statuses do |t|
      t.string :source
      t.date :data_upto
      t.date :last_run
      t.boolean :succeeded
    end

    ImportStatus.create!(source: ImportStatus::Source::BSEBHAV, data_upto: '31/12/2011')

  end
end
