class StockPerformance

  def initialize(stock)
    @stock = stock
  end

  def returns
    latest_quote = EqQuote.find_by_stock_id(@stock.id, order: 'date desc', limit: 1)
    return {} unless latest_quote
    max_date = latest_quote.date

    {
        '1 Day' => return_percentage(find_earliest_quote(@stock.id, max_date - 1), latest_quote),
        '1 Week' => return_percentage(find_earliest_quote(@stock.id, max_date - 7), latest_quote),
        '1 Month' => return_percentage(find_earliest_quote(@stock.id, max_date - 1.month), latest_quote),
        '90 Days' => return_percentage(find_earliest_quote(@stock.id, max_date - 90), latest_quote),
        '1 Year' => return_percentage(find_earliest_quote(@stock.id, max_date - 365), latest_quote)
    }
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