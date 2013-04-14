require 'spec_helper'

describe "FoQuotes" do

  it "should not exists without stock" do
    lambda { FoQuote.create!(:stock_id => 0) }.should raise_exception(ActiveRecord::InvalidForeignKey)
    FoQuote.find_by_stock_id(0).should be_nil
  end

  describe :apply_factor do

    before(:each) do
      @stock = Stock.create!(:symbol => 'MyStock')
    end

    it 'should apply factor on all past futures quotes' do
      ex_date = Date.parse('20130111')
      (Date.parse('20130101') .. ex_date - 1).each do |date|
        FoQuote.create!(stock: @stock, open: 100, high: 1000, low: 10, close: 200, traded_quantity: 5000, date: date, fo_type: FoQuote::FUTURES)
      end
      factor = 0.25
      FoQuote.apply_factor(@stock, factor, ex_date)
      FoQuote.where(stock_id: @stock.id).all.each do |quote|
        quote.open.should == 100.0 * factor
        quote.high.should == 1000.0 * factor
        quote.low.should == 10.0 * factor
        quote.close.should == 200.0 * factor
        quote.traded_quantity.should == 5000.0 * factor
      end
    end

    it 'should handle no quotes scenario' do
      FoQuote.apply_factor(@stock, 1, Date.today)
    end

    it 'should apply factor only on specified stock' do
      ex_date = Date.parse('20130111')

      stock_b = Stock.create! symbol: 'B'
      quote_for_b = FoQuote.create!(stock: stock_b, open: 100, high: 1000, low: 10, close: 200, traded_quantity: 5000, date: ex_date - 1, fo_type: FoQuote::FUTURES)

      FoQuote.apply_factor(@stock, 0.25, ex_date)

      quote = FoQuote.where(stock_id: stock_b.id).first

      quote.open.to_f.should == 100.0
      quote.high.should == 1000.0
      quote.low.should == 10.0
      quote.close.should == 200.0
      quote.traded_quantity.should == 5000.0

    end

    it 'should not apply factor on options quotes' do
      ex_date = Date.parse('20130111')
      FoQuote.create!(stock: @stock, open: 100, high: 1000, low: 10, close: 200, traded_quantity: 5000, date: ex_date - 1, fo_type: FoQuote::PUT)
      FoQuote.create!(stock: @stock, open: 100, high: 1000, low: 10, close: 200, traded_quantity: 5000, date: ex_date - 1, fo_type: FoQuote::CALL)
      FoQuote.apply_factor(@stock, 0.25, ex_date)
      FoQuote.where(stock_id: @stock.id).all.each do |quote|
        quote.open.should == 100.0
        quote.high.should == 1000.0
        quote.low.should == 10.0
        quote.close.should == 200.0
        quote.traded_quantity.should == 5000.0
      end

    end

  end
end