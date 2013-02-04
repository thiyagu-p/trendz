namespace :data do
  desc "Import Equity Quotes"
  task :sync => :environment do
    Importer::SymbolChange.new.import
    Importer::StockMaster.new.import
    Importer::EquityBhav.new.import
    Importer::FoBhav.new.import
    Importer::YahooData.new.import
    Importer::MarketActivityImporter.new.import
    Importer::NiftyLiveImporter.new.import
  end

  desc "import corporate action and results"
  task :corp_details => :environment do
    Importer::StockMaster.new.import
    Importer::CorporateActionImporter.new.import
    Importer::CorporateResultImporter.new.import
  end

end