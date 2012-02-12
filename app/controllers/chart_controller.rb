class ChartController < ApplicationController

  def index
    @stocks = Stock.order(:symbol)
  end

  def show
    @stock = Stock.find_by_symbol(params[:symbol])
    max_date = EqQuote.where(stock_id: @stock.id).maximum(:date)
    @quotes = EqQuote.find_all_by_stock_id(@stock.id, :order => :date, :conditions => "date >= '#{max_date - 365}'")
    @returns = {
        '1 Week' => return_percentage(find_earliest_quote(@stock.id, max_date - 7), @quotes.last),
        '1 Month' => return_percentage(find_earliest_quote(@stock.id, max_date - 1.month), @quotes.last),
        '90 Days' => return_percentage(find_earliest_quote(@stock.id, max_date - 90), @quotes.last),
        '1 Year' => return_percentage(find_earliest_quote(@stock.id, max_date - 365), @quotes.last)
    }
    render :layout => false
  end

  private

  def find_earliest_quote(stock_id, date)
    EqQuote.find_by_stock_id(stock_id, order: :date, conditions: "date >='#{date}'")
  end

  def return_percentage(start_quote, end_quote)
    return 0.0 if start_quote.nil? || end_quote.nil?
    (end_quote.close - start_quote.close) / start_quote.close * 100
  end

end
