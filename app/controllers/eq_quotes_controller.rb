class EqQuotesController < ApplicationController
  def show
    @stock = Stock.find_by_symbol(params[:stock_id])
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{Date.today - 100}'")
    render :json => @quotes.collect{|q| [q.date, q.open, q.high, q.low, q.close, q.traded_quantity]}
  end
end
