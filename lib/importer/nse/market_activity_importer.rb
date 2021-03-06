require 'net/http'
require 'nokogiri'
require 'csv'
require 'roo'


module Importer
  module Nse
    class MarketActivityImporter
      include Connection

      def import
        begin
          import_equity_data
          import_fo_data
        rescue => e
          puts "Nse::MarketActivityImporter Failed - #{e.message}"
          puts e.backtrace
        end
      end

      def import_fo_data
        start_date = MarketActivity.maximum('date', :conditions => 'fii_index_futures_buy is not null')
        start_date = Date.parse('1/1/2011') if start_date == nil
        (start_date .. Date.today).each do |date|
          import_and_save_data_for(date)
        end
      end

      def import_equity_data
        start_date = ((MarketActivity.maximum('date') or Date.parse('31/12/2009')) + 1.day)
        end_date = Date.today
        if start_date <= end_date
          url = "/products/dynaContent/equities/equities/eq_fiidii_archives.jsp?category=all&check=new&fromDate=#{start_date.strftime('%d-%m-%Y')}&toDate=#{end_date.strftime('%d-%m-%Y')}"
          Rails.logger.info "Processing Equity market activity @ #{url}"
          doc = Nokogiri::HTML(get(url).body)
          doc.css('tr[height="20"]').each do |row|
            cells = row.css('td')
            next unless cells[0].text =~ /FII|DII/
            market_activity = MarketActivity.find_or_create_by(date: Date.parse(cells[1].text))
            market_activity.update_attribute("#{cells[0].text.downcase}_buy_equity", cells[2].text)
            market_activity.update_attribute("#{cells[0].text.downcase}_sell_equity", cells[3].text)
            market_activity.save!
          end
        end
      end

      private
      def save_to_temp_file(path)
        response = get(path)
        unless response.class == Net::HTTPNotFound
          file_path = File.join('data', File.basename(path))
          open(file_path, "wb") { |file| file.write response.body }
          file_path
        end
      end

      def import_and_save_data_for(date)
        xls_path = "/content/fo/fii_stats_#{date.strftime('%d-%b-%Y')}.xls"
        Rails.logger.info "Processing F&O market data - #{date} : #{xls_path}"
        market_activity = MarketActivity.find_by_date(date)
        if market_activity
          temp_file = save_to_temp_file(xls_path)
          parse_and_save_data(market_activity, temp_file) if temp_file
        end
      end

      def parse_and_save_data(market_activity, temp_file)
        excel = Roo::Excel.new(temp_file)
        excel.default_sheet = excel.sheets.first
        4.upto(7) do |row|
          next unless excel.cell(row, 'A') =~ /INDEX|STOCK/
          row_downcase_gsub = excel.cell(row, 'A').downcase!.gsub!(' ', '_')
          market_activity.update_attribute("fii_#{row_downcase_gsub}_buy", excel.cell(row, 'C'))
          market_activity.update_attribute("fii_#{row_downcase_gsub}_sell", excel.cell(row, 'E'))
          market_activity.update_attribute("fii_#{row_downcase_gsub}_oi", excel.cell(row, 'F'))
          market_activity.update_attribute("fii_#{row_downcase_gsub}_oi_value", excel.cell(row, 'G'))
        end
        market_activity.save!
      end

      def find_csv_url(content)
        doc = Nokogiri::HTML(content)
        anchor_elements = (doc.css('a').reject { |x| x.content != ' Download file in csv format' })
        anchor_elements.length > 0 and anchor_elements.first['href']
      end
    end
  end
end