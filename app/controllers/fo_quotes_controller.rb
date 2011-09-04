class FoQuotesController < ApplicationController

  def show
    @stock = Stock.find_by_symbol(params[:stock_id])
    @quotes = FoQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{Date.today - 60}'")
    render :json => @quotes.collect{|q| [q.date, q.expiry_date, q.expiry_series, q.fo_type, q.strike_price,
                                         q.open, q.high, q.low, q.close, q.traded_quantity,
                                         q.open_interest, (q.change_in_open_interest / q.open_interest * 100).round(2)]}
  end
end
