class FoChartsController < ApplicationController

  def index
    @stocks = Stock.where('id in (select distinct stock_id from fo_quotes)').to_a
  end

  def show_data
    @stock = Stock.find_by_symbol(params[:symbol])
    from_date = Date.today - 40
    fo_quotes = FoQuote.find_all_by_stock_id(@stock.id, :order => 'date desc', :conditions => "date >= '#{from_date}' and expiry_series = 'current'")
    @headers = (fo_quotes.inject(Set.new) {|set, quote| set << quote.strike_price}).sort
    @fo_quotes_by_date = fo_quotes.group_by(&:date)
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :conditions => "date >= '#{from_date}'", :order => 'date asc')
    @future_quotes = fo_quotes.inject([]) {|arr, quote| arr << quote if quote.future?; arr}
    render :layout => false
  end

  def show_ratio
    @stock = Stock.find_by_symbol(params[:symbol])
    start_date = Date.today - 90
    @ratio_data = FoQuote.connection.select_all("select date, sum(case when fo_type like 'C%' then open_interest else 0 end) as total_call_oi, sum(case when fo_type like 'P%' then open_interest else 0 end) as total_put_oi, sum(case when fo_type like 'C%' then traded_quantity else 0 end) as total_call, sum(case when fo_type like 'P%' then traded_quantity else 0 end) as total_put from fo_quotes where stock_id = #{@stock.id} and date >= '#{start_date}' and fo_type <> 'XX' and expiry_series in ('current', 'next') group by date order by date")
    quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => 'date', :conditions => "date >= '#{start_date}'")
    @price_movement = quotes.collect do |quote|
      [quote.date.to_s, quote.close.to_f]
    end
    render :layout => false
  end
end