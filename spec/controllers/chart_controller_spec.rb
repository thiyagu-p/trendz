require 'spec_helper'

describe ChartController do

  it "should calculate returns" do
    stock = Stock.create(symbol: 'RIL')
    (0..365).each { |number| EqQuote.create(stock: stock, date: Date.today - number, close: (366 - number))}

    get :show, symbol: stock.symbol

    assigns(:returns)['1 Week'].to_f.should == (366.0 - 359.0) / 359.0 * 100.0
  end
end
