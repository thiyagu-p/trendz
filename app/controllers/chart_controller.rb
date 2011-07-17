class ChartController < ApplicationController

  def index
    @stocks = Stock.order(:symbol)
  end

  def show
    @stock = Stock.find_by_symbol(params[:symbol])
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{Date.today - 365}'")
    render :layout => false
  end

end
