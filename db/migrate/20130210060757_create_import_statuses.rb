class CreateImportStatuses < ActiveRecord::Migration
  def change
    create_table :import_statuses do |t|
      t.string :source
      t.date :data_upto
      t.date :last_run
      t.boolean :completed
    end

    ImportStatus.create!(source: ImportStatus::Source::BSE_BHAV, data_upto: '31/12/2011')
    ImportStatus.create!(source: ImportStatus::Source::BSE_STOCKMASTER)
    ImportStatus.create!(source: ImportStatus::Source::NSE_SYMBOL_CHANGE)
    ImportStatus.create!(source: ImportStatus::Source::NSE_EQUITIES_BHAV, data_upto: EqQuote.maximum(:date))
    ImportStatus.create!(source: ImportStatus::Source::NSE_DERIVATIVES_BHAV, data_upto: FoQuote.maximum(:date))
    ImportStatus.create!(source: ImportStatus::Source::NSE_CORPORATE_ACTION)
    ImportStatus.create!(source: ImportStatus::Source::NSE_CORPORATE_RESULT)
    ImportStatus.create!(source: ImportStatus::Source::NSE_STOCK_MASTER)
    ImportStatus.create!(source: ImportStatus::Source::YAHOO_QUOTES)

  end
end
