class StatusController < ApplicationController

  def show
    @market_activity_eq = MarketActivity.maximum(:date)
    @market_activity_fo = MarketActivity.maximum('date', :conditions => 'fii_index_futures_buy is not null')
  end

end
