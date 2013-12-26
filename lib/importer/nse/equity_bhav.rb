require 'zip/zipfilesystem'
require 'csv'

module Importer
  module Nse
    class EquityBhav
      include Connection, BhavHandler
      model EqQuote
      sub_path 'EQUITIES'
      file_name_prefix 'cm'
      startdate '31/12/2010'

      def process_row(columns)
        return unless columns[1] =~ /EQ|BE|DR/
        stock = Stock.find_or_create_by(symbol: columns[0], nse_series: Stock::NseSeries::EQUITY)
        date = columns[10].to_date
        EqQuote.create!(:stock => stock, :open => columns[2], :high => columns[3], :low => columns[4], :close => columns[5], :previous_close => columns[7], :traded_quantity => columns[8], :date => date)
        MovingAverageCalculator.update(date, stock)
      end
    end
  end
end
