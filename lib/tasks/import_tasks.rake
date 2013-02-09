namespace :data do
  desc "Import Equity Quotes"
  task :sync => :environment do
    Importer::Nse::SymbolChange.new.import
    Importer::Nse::StockMaster.new.import
    Importer::Nse::EquityBhav.new.import
    Importer::Nse::FoBhav.new.import
    Importer::Nse::YahooData.new.import
    Importer::MarketActivityImporter.new.import
    Importer::Nse::NiftyLiveImporter.new.import
  end

  desc "import corporate action and results"
  task :corp_details => :environment do
    Importer::Nse::StockMaster.new.import
    Importer::Nse::CorporateActionImporter.new.import
    Importer::Nse::CorporateResultImporter.new.import
  end

  desc 'import bse data'
  task sync_bse: :environment do
    Importer::Bse::StockMaster.new.import
  end
end