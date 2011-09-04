class StatusController < ApplicationController

  def show
    @eq_date = EqQuote.maximum(:date)
    @fo_date = FoQuote.maximum(:date)
    @index_date = EqQuote.maximum(:date, :conditions => "stock_id = #{Stock.find_by_symbol('NIFTY').id}")
  end

end
