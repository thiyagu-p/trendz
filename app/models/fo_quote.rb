class FoQuote < ActiveRecord::Base
  belongs_to :stock

  module ExpirySeries
    CURRENT = 'current'
    NEXT = 'next'
    FAR = 'far'
    UNKNOWN = 'unknown'
  end

  FUTURES = 'XX'
  PUT = 'PE'
  CALL = 'CE'

  def future?
    fo_type == FUTURES
  end

  def self.apply_factor(stock, factor, ex_date)
    fields = [:open, :high, :low, :close, :traded_quantity].collect do |field|
      " #{field} = #{field} * #{factor}"
    end
    self.update_all("#{fields.join(',')} where stock_id = #{stock.id} and date < '#{ex_date}' and fo_type = '#{FUTURES}'")
  end

end
