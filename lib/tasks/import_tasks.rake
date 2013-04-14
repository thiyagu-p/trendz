namespace :data do
  desc "Import Equity Quotes"
  task :sync => :environment do
    Importer::Nse::SymbolChange.new.import
    Importer::Nse::StockMaster.new.import
    Importer::Nse::EquityBhav.new.import
    Importer::Nse::FoBhav.new.import
    Importer::Nse::YahooData.new.import
    Importer::Nse::MarketActivityImporter.new.import
    Importer::Nse::NiftyLiveImporter.new.import
    Importer::Bse::StockMaster.new.import
    Importer::Bse::EquityBhav.new.import
  end

  desc "import corporate action"
  task :corp_action => :environment do
    Importer::Nse::StockMaster.new.import
    Importer::Nse::CorporateActionImporter.new.import
  end

  desc "import corporate results"
  task :corp_results => :environment do
    Importer::Nse::StockMaster.new.import
    Importer::Nse::CorporateActionImporter.new.import
  end
end