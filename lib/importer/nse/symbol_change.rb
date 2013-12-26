require 'csv'

module Importer
  module Nse
    class SymbolChange
      include Connection

      BASE_PATH = "/content/equities/symbolchange.csv"

      def import
        begin
          Rails.logger.info "Importing symbol changes"
          apply_changes import_data
          ImportStatus.completed_upto_today(ImportStatus::Source::NSE_SYMBOL_CHANGE)
        rescue => e
          Rails.logger.error "#{e.inspect}"
          ImportStatus.failed(ImportStatus::Source::NSE_SYMBOL_CHANGE)
        end
      end

      def import_data
        response = get(BASE_PATH)
        raise IOError "Importing symbol changes failed, url might have change #{BASE_PATH}" if response.class == Net::HTTPNotFound
        parse_csv(response.body)
      end

      private

      def parse_csv(data)
        symbol_changes = []
        header = true
        CSV.parse(data) do |line|
          (header = false; next) if header
          break if line.size < 4
          symbol_changes << {:date => line[3].to_date, :symbol => line[1], :new_symbol => line[2]}
        end
        symbol_changes.sort! { |a, b| a[:date] <=> b[:date] }
      end

      def apply_changes(symbol_changes)
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
        EqQuote.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        FoQuote.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        BonusAction.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        DividendAction.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        FaceValueAction.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        CorporateActionError.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        CorporateResult.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        EquityTransaction.where("stock_id = #{new_stock.id}").update_all("stock_id = #{stock.id}")
        ActiveRecord::Base.connection.execute "update stocks_watchlists set stock_id = #{stock.id} where stock_id = #{new_stock.id}"
        new_stock.delete
        (from_date .. Date.today).each { |date| MovingAverageCalculator.update(date, stock) }
      end
    end
  end
end
