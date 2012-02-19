class ChartController < ApplicationController

  def index
    @stocks = Stock.order(:symbol)
  end

  def show
    @stock = Stock.find_by_symbol(params[:symbol])
    max_date = EqQuote.where(stock_id: @stock.id).maximum(:date) || Date.today
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{max_date - 365}'")
    render :layout => false
  end
end
