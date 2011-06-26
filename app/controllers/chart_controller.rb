class ChartController < ApplicationController

  def index
    @stocks = Stock.all
  end

  def show
    @quotes = EqQuote.find_all_by_stock_id(params[:id], :order => :date)
    @stock = Stock.find(params[:id])
    render :layout => false
  end

end
