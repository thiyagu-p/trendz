require 'zip/zipfilesystem'
require 'csv'

module Importer
  class EquityBhav
    include NseConnection, BhavHandler
    model EqQuote
    sub_path 'EQUITIES'
    file_name_prefix 'cm'

    def process_row(columns)
      return unless columns[1] =~ /EQ|BE|DR/
      stock = Stock.find_or_create_by_symbol(columns[0])
      date = columns[10].to_date
      EqQuote.create!(:stock => stock, :open => columns[2], :high => columns[3], :low => columns[4], :close => columns[5], :previous_close => columns[7], :traded_quantity => columns[8], :date => date)
      MovingAverageCalculator.update(date, stock)
    end
  end
end
