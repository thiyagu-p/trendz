namespace :import do
  namespace :quote do
    desc "Import Equity Quotes"
    task :equity => :environment do
      Importer::EquityBhav.new.import
    end
  end
end