class StockPerformance

  def initialize(stock)
    @stock = stock
  end

  PERIOD = [1, 7, 30, 90, 365]

  def returns
    latest_quote = EqQuote.find_by_stock_id(@stock.id, order: 'date desc', limit: 1)
    return {} unless latest_quote
    max_date = latest_quote.date

    PERIOD.inject({}) do |hash, days|
      hash["#{days} Days"] = return_percentage(find_earliest_quote(@stock.id, max_date - days), latest_quote)
      hash
    end
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