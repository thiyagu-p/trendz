require 'net/http'
require 'zip/zipfilesystem'
require 'csv'

module Importer
  class EquityBhav

    def parse_bhav_file(file_name, zip_file_name)
      begin
        Stock.transaction do
          Zip::ZipFile.open("data/#{zip_file_name}") do |zipfile|
            CSV::Reader.parse(zipfile.file.read(file_name)) do |line|
              next unless line[1] =~ /EQ|BE|DR/
              stock = Stock.find_or_create_by_symbol(line[0])
              date = line[10].to_date
              EqQuote.create!(:stock => stock, :open => line[2], :high => line[3], :low => line[4], :close => line[5], :previous_close => line[7], :traded_quantity => line[8], :date => date)
              MovingAverageCalculator.update(date, stock)
            end
          end
        end
      rescue Zip::ZipError => e
        p e
      end
    end

    def import
      start_date = (EqQuote.maximum('date') or Date.parse('12/31/2004')) + 1
      http = Net::HTTP.new(NSE_URL)
      (start_date .. Date.today).each do |date|
        Rails.logger.info "processing equity bhav for #{date}"
        month = date.strftime("%b").upcase
        file_name = "cm#{date.strftime("%d")}#{month}#{date.year}bhav.csv"
        zip_file_name = "#{file_name}.zip"
        file_path = "/content/historical/EQUITIES/#{date.year}/#{month}/#{zip_file_name}"
        response = http.request_get(file_path, 'User-Agent'=>'Firefox')
        next if response.class == Net::HTTPNotFound
        open("data/#{zip_file_name}", 'w') { |file| file << response.body }
        parse_bhav_file(file_name, zip_file_name)
      end
    end

  end
end
