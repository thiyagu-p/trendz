require "spec_helper"

describe StockPerformance do

  it "should calculate stock performance" do
    stock = Stock.create(symbol: 'RIL')
    (0..365).each { |number| EqQuote.create(stock: stock, date: Date.today - number, close: (366 - number))}

    stock_performance = StockPerformance.new(stock)

    stock_performance.returns['1 Week'].to_f.should == (366.0 - 359.0) / 359.0 * 100.0

  end

  it "should handle new stock" do
    stock = Stock.create(symbol: 'RIL')
    stock_performance = StockPerformance.new(stock)
    stock_performance.returns.count.should be_zero

  end
end