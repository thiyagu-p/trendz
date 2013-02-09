require 'csv'

module Importer
  class StockMaster
    include NseConnection

    def import
      Rails.logger.info "Importing Stock Master"
      file_path = "/content/equities/EQUITY_L.csv"
      response = get(file_path)
      Rails.logger.error "Importing stock master failed url might have change #{file_path}" and return if response.class == Net::HTTPNotFound
      parse_csv(response.body)
    end

    private
    def parse_csv(data)
      CSV.parse(data, {headers: true}) do |row|
        symbol, name, series, date_of_listing, paid_up_value, market_lot, isin, face_value = row.fields
        stock = Stock.find_by_isin(isin) || Stock.find_or_create_by_symbol(symbol)
        stock.update_attributes!(symbol: symbol, name: name, face_value: face_value, isin: isin, nse_series: series, nse_active: true)
      end
    end
  end
end
