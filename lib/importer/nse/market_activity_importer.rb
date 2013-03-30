require 'net/http'
require 'nokogiri'
require 'csv'
require 'roo'


module Importer
  module Nse
    class MarketActivityImporter
      include Connection

      def import
        import_equity_data
        import_fo_data
      end

      def import_fo_data
        start_date = MarketActivity.maximum('date', :conditions => 'fii_index_futures_buy is not null')
        start_date = Date.parse('1/1/2011') if start_date == nil
        (start_date .. Date.today).each do |date|
          import_and_save_data_for(date)
        end
      end

      def import_equity_data
        start_date = ((MarketActivity.maximum('date') or Date.parse('31/12/2009')) + 1.day).strftime('%d-%m-%Y')
        end_date = Date.today.strftime('%d-%m-%Y')
        return unless start_date <= end_date
        url = "/products/dynaContent/equities/equities/eq_fiidii_archives.jsp?category=all&check=new&fromDate=#{start_date}&toDate=#{end_date}"
        Rails.logger.info "Processing Equity market activity @ #{url}"
        response = get(url)
        csv_url = find_csv_url(response.body)
        return unless csv_url
        csv_content = get(csv_url).body
        CSV.parse(csv_content) do |row|
          next unless row[0] =~ /FII|DII/
          market_activity = MarketActivity.find_or_create_by_date(Date.parse(row[1]))
          market_activity.update_attribute("#{row[0].downcase}_buy_equity", row[2])
          market_activity.update_attribute("#{row[0].downcase}_sell_equity", row[3])
          market_activity.save!
        end
      end

      private
      def save_to_temp_file(path)
        response = get(path).body
        file_path = File.join('data', File.basename(path))
        open(file_path, "wb") { |file| file.write response }
        file_path
      end

      def import_and_save_data_for(date)
        xls_path = "/content/fo/fii_stats_#{date.strftime('%d-%b-%Y')}.xls"
        Rails.logger.info "Processing F&O market data - #{date} : #{xls_path}"
        market_activity = MarketActivity.find_by_date(date)
        if market_activity
          excel = Roo::Excel.new(save_to_temp_file(xls_path))
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
      end

      def find_csv_url(content)
        doc = Nokogiri::HTML(content)
        anchor_elements = (doc.css('a').reject { |x| x.content != ' Download file in csv format' })
        anchor_elements.length > 0 and anchor_elements.first['href']
      end
    end
  end
end