class ChartsController < ApplicationController

  before_filter :load_stock_list

  def index

  end

  def show
    @stock = Stock.find_by_symbol(params[:id])
    no_of_days = (params[:days] || 365).to_i
    max_date = EqQuote.where(stock_id: @stock.id).maximum(:date) || Date.today
    start_date = max_date - no_of_days
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{start_date}'")
    @results = CorporateResult.where("stock_id =  #{@stock.id} and quarter_end >= '#{start_date}'").all
  end

  private
  def load_stock_list
    @stocks = Stock.order(:symbol)
  end
end
