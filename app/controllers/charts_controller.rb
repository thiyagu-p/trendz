class ChartsController < ApplicationController

  before_filter :load_stock_list

  def index

  end

  def show
    @stock = Stock.find_by_symbol(params[:id])
    max_date = EqQuote.where(stock_id: @stock.id).maximum(:date) || Date.today
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{max_date - 365}'")
  end

  private
  def load_stock_list
    @stocks = Stock.order(:symbol)
  end
end
