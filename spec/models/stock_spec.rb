require "spec_helper"

describe Stock do

  it "should give latest quote" do
    stock = Stock.create
    first = EqQuote.create(stock: stock, date: Date.parse('01/01/2012'))
    latest = EqQuote.create(stock: stock, date: Date.parse('05/01/2012'))
    second = EqQuote.create(stock: stock, date: Date.parse('03/01/2012'))

    stock.latest_quote.should == latest
  end
end