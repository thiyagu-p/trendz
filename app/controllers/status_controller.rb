class StatusController < ApplicationController

  def show
    @eq_date = EqQuote.maximum(:date)
    @fo_date = FoQuote.maximum(:date)
    @index_date = EqQuote.maximum(:date, :conditions => "stock_id = #{Stock.find_by_symbol('NIFTY').id}")
    @market_activity_eq = MarketActivity.maximum(:date)
    @market_activity_fo = MarketActivity.maximum('date', :conditions => 'fii_index_futures_buy is not null')
  end

end
