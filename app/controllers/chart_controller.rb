class ChartController < ApplicationController

  def index
    @stocks = Stock.order(:symbol)
  end

  def show
    @quotes = EqQuote.find_all_by_stock_id(params[:id], :order => :date, :conditions => "date >= '#{Date.today - 365}'")
    @stock = Stock.find(params[:id])
    render :layout => false
  end

end
