require 'zip/zipfilesystem'
require 'csv'


module Importer
  module Nse
    class FoBhav
      include Connection, BhavHandler
      model FoQuote
      sub_path 'DERIVATIVES'
      file_name_prefix 'fo'
      startdate '31/12/2010'

      def initialize
        @stock_cache = {}
      end

      def process_row(columns)
        return if columns[0] == 'INSTRUMENT' or columns[10] == '0'
        @stock_cache[columns[1]] or (@stock_cache[columns[1]] = Stock.find_or_create_by(symbol: columns[1], nse_series: (columns[0] =~ /IDX$/ ? Stock::NseSeries::INDEX : Stock::NseSeries::EQUITY)))
        FoQuote.create!(:stock => @stock_cache[columns[1]], :expiry_date => columns[2].to_date, :strike_price => columns[3], :fo_type => columns[4], :open => columns[5], :high => columns[6], :low => columns[7],
                        :close => columns[8], :traded_quantity => columns[10], :open_interest => columns[12], :change_in_open_interest => columns[13], :date => columns[14].to_date, :expiry_series => identify_expiry_series(columns[14].to_date, columns[2].to_date))
      end

      def identify_expiry_series(date, expiry_date)
        return FoQuote::ExpirySeries::CURRENT if date.month == expiry_date.month and date.year == expiry_date.year

        if (expiry_date - 1.month).strftime('%Y%m') == date.strftime('%Y%m')
          expiry_date_for = expiry_date_for_month(date.strftime('%Y%m'))
          return FoQuote::ExpirySeries::CURRENT if expiry_date_for.nil? or expiry_date_for < date
          return FoQuote::ExpirySeries::NEXT
        end
        return FoQuote::ExpirySeries::FAR if (expiry_date - 2.month).strftime('%Y%m') == date.strftime('%Y%m')
        FoQuote::ExpirySeries::UNKNOWN
      end

      def expiry_date_for_month(str_date)
        @monthwise_expiry_date ||= {}
        return @monthwise_expiry_date[str_date] if @monthwise_expiry_date[str_date]
        FoQuote.select('distinct expiry_date').each { |quote| @monthwise_expiry_date[quote.expiry_date.strftime('%Y%m')] = quote.expiry_date }
        @monthwise_expiry_date[str_date]
      end

    end
  end
end