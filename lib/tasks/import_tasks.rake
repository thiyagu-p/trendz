namespace :data do
  desc "Import Equity Quotes"
  task :sync => :environment do
    Importer::SymbolChange.new.import
    Importer::EquityBhav.new.import
    Importer::FoBhav.new.import
    Importer::YahooData.new.import
    Importer::MarketActivityImporter.new.import
    Importer::NiftyLiveImporter.new.import
  end

  task :corp_action => :environment do
    Importer::CorporateActionImporter.new.import
  end
end