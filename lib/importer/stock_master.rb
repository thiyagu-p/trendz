require 'csv'

module Importer
  class StockMaster
    include NseConnection

    def parse_csv(data)
      header = true
      CSV.parse(data) do |line|
        (header = false; next) if header
        stock = Stock.find_or_create_by_symbol(line[0])
        stock.update_attributes!(name: line[1], face_value: line[7], isin: line[6], series: line[2])
      end
    end

    def import
      Rails.logger.info "Importing Stock Master"
      file_path = "/content/equities/EQUITY_L.csv"
      response = get(file_path)
      Rails.logger.error "Importing stock master failed url might have change #{file_path}" and return if response.class == Net::HTTPNotFound
      parse_csv(response.body)
    end

  end
end
