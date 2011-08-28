require 'csv'

module Importer
  class SymbolChange
    include NseConnection

    def parse_csv(data)
      symbol_changes = []
      header = true
      CSV.parse(data) do |line|
        (header = false; next) if header
        break if line.size < 4
        symbol_changes << {:date => line[3].to_date, :symbol => line[1], :new_symbol => line[2]}
      end
      symbol_changes.sort! {|a, b| a[:date] <=> b[:date]}
      Stock.transaction do
        symbol_changes.each do |hash|
          stock = Stock.find_by_symbol(hash[:symbol])
          next unless stock
          migrate_new_stock_references_and_delete(stock, hash[:new_symbol], hash[:date])
          stock.update_attribute(:symbol, hash[:new_symbol])
        end
      end
    end

    def migrate_new_stock_references_and_delete(stock, new_symbol, from_date)
      new_stock = Stock.find_by_symbol(new_symbol)
      return unless new_stock
      EqQuote.update_all "stock_id = #{stock.id}", "stock_id = #{new_stock.id}"
      new_stock.delete
      (from_date .. Date.today).each {|date| MovingAverageCalculator.update(date, stock)}
    end


    def import
      Rails.logger.info "Importing symbol changes"
      file_path = "/content/equities/symbolchange.csv"
      response = get(file_path)
      Rails.logger.error "Importing symbol changes failed url might have change #{file_path}" and return if response.class == Net::HTTPNotFound
      parse_csv(response.body)
    end

  end
end
