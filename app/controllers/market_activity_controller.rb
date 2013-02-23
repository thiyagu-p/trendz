class MarketActivityController < ApplicationController

  def chart
    start_date = Date.today - 60
    nifty = Stock.find_by_symbol('NIFTY')
    equity_max_date = EqQuote.maximum('date', :conditions => "stock_id = #{nifty.id}")
    fo_max_date = MarketActivity.maximum('date', :conditions => 'fii_index_futures_buy is not null')
    max_date = equity_max_date < fo_max_date ? equity_max_date : fo_max_date
    @market_activities = MarketActivity.all(:conditions => "date > '#{start_date}' and date <= '#{max_date}'", :order => 'date asc')
    @nifty_quotes = nifty ? EqQuote.all(:conditions => "date > '#{start_date}'  and date <= '#{max_date}' and stock_id = #{nifty.id}") : []
  end
end