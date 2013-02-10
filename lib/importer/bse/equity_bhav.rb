module Importer
  module Bse
    class EquityBhav
      include Importer::Connectable

      BASE_URL = '/download/BhavCopy/Equity/'

      def import
        begin
          import_status = ImportStatus.find_by_source(ImportStatus::Source::BSE_BHAV)

          start_date = import_status.data_upto + 1
          (start_date .. Date.today).each { |date| import_for(date) }
          ImportStatus.completed(ImportStatus::Source::BSE_BHAV)
        rescue => e
          Rails.logger.error "#{e.inspect}"
          ImportStatus.failed(ImportStatus::Source::BSE_BHAV)
        end
      end

      private

      def import_for(date)
        Rails.logger.info "processing bse bhav for #{date}"
        file_name, file_path, zip_file_name = file_names(date)
        response = connection(BSE_URL).request_get(file_path)
        unless response.class == Net::HTTPNotFound
          open("data/#{zip_file_name}", 'wb') { |file| file << response.body }
          parse_bhav_file(file_name, zip_file_name, date)
        end
      end

      def file_names(date)
        date_str = date.strftime("%d%m%y")
        file_name = "EQ#{date_str}.CSV"
        zip_file_name = "eq#{date_str}_csv.zip"
        file_path = "#{BASE_URL}#{zip_file_name}"
        return file_name, file_path, zip_file_name
      end

      def parse_bhav_file(file_name, zip_file_name, date)
        Stock.transaction do
          Zip::ZipFile.open("data/#{zip_file_name}") do |zipfile|
            CSV.parse(zipfile.file.read(file_name), {headers: true}) do |row|
              process_row(row, date)
            end
          end
          ImportStatus.find_by_source(ImportStatus::Source::BSE_BHAV).update_attributes! data_upto: date
        end
      end

      def process_row(row, date)
        bse_code, name, group, type, open, high, low, close, last, previous_close, no_trades, traded_qty, net_turnov, un_used = row.fields

        return if (stock = Stock.find_by_bse_code(bse_code)).nil?
        return unless EqQuote.find_by_stock_id_and_date(stock.id, date).nil?

        EqQuote.create!(stock: stock, open: open, high: high, low: low, close: close, previous_close: previous_close, :traded_quantity => traded_qty, :date => date)
        MovingAverageCalculator.update(date, stock)
      end
    end
  end
end