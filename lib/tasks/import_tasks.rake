namespace :data do
  desc "Import Equity Quotes"
  task :sync => :environment do
    Importer::SymbolChange.new.import
    Importer::EquityBhav.new.import
    Importer::FoBhav.new.import
    Importer::YahooDate.new.import
  end
end