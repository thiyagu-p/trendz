require 'spec_helper'

describe "EqQuotes" do

  it "should not exists without stock" do
    expect{ EqQuote.create!(:stock_id => 0) }.to raise_error
    EqQuote.find_by(stock_id: 0).should be_nil
  end

  describe :apply_factor do

    before(:each) do
      @stock = Stock.create!(:symbol => 'MyStock')
    end

    it 'should apply factor on all past quotes' do
      ex_date = Date.parse('20130111')
      (Date.parse('20130101') .. ex_date - 1).each do |date|
        EqQuote.create!(stock: @stock, open: 100, high: 1000, low: 10, close: 200, previous_close: 300,
                        mov_avg_10d: 400, mov_avg_50d: 500, mov_avg_200d: 600, traded_quantity: 5000, date: date)
      end
      factor = 0.25
      EqQuote.apply_factor(@stock, factor, ex_date)
      EqQuote.where(stock_id: @stock.id).to_a.each do |quote|
        quote.open.should == 100.0 * factor
        quote.high.should == 1000.0 * factor
        quote.low.should == 10.0 * factor
        quote.close.should == 200.0 * factor
        quote.previous_close.should == 300.0 * factor
        quote.mov_avg_10d.should == 400.0 * factor
        quote.mov_avg_50d.should == 500.0 * factor
        quote.mov_avg_200d.should == 600.0 * factor
        quote.traded_quantity.should == 5000.0 * factor
      end
    end

    it 'should only recalculate moving averages on future quotes' do
      ex_date = Date.parse('20130111')
      (ex_date .. ex_date + 3).each do |date|
        EqQuote.create!(stock: @stock, open: 100, high: 1000, low: 10, close: 200, previous_close: 300,
                        mov_avg_10d: 400, mov_avg_50d: 500, mov_avg_200d: 600, traded_quantity: 5000, date: date)
      end
      factor = 0.25
      MovingAverageCalculator.expects(:update).with(ex_date, @stock)
      MovingAverageCalculator.expects(:update).with(ex_date + 1, @stock)
      MovingAverageCalculator.expects(:update).with(ex_date + 2, @stock)
      MovingAverageCalculator.expects(:update).with(ex_date + 3, @stock)

      EqQuote.apply_factor(@stock, factor, ex_date)

      EqQuote.where(stock_id: @stock.id).to_a.each do |quote|
        quote.open.should == 100.0
        quote.high.should == 1000.0
        quote.low.should == 10.0
        quote.close.should == 200.0
        quote.previous_close.should == 300.0
        quote.traded_quantity.should == 5000.0
      end
    end

    it 'should handle no quotes scenario' do
      EqQuote.apply_factor(@stock, 1, Date.today)
    end

    it 'should apply factor only on specified stock' do
      ex_date = Date.parse('20130111')

      stock_b = Stock.create! symbol: 'B'
      quote_for_b = EqQuote.create!(stock: stock_b, open: 100, high: 1000, low: 10, close: 200, previous_close: 300,
                      mov_avg_10d: 400, mov_avg_50d: 500, mov_avg_200d: 600, traded_quantity: 5000, date: ex_date - 1)

      EqQuote.apply_factor(@stock, 0.25, ex_date)

      quote = EqQuote.where(stock_id: stock_b.id).first

      quote.open.to_f.should == 100.0
      quote.high.should == 1000.0
      quote.low.should == 10.0
      quote.close.should == 200.0
      quote.previous_close.should == 300.0
      quote.mov_avg_10d.should == 400.0
      quote.mov_avg_50d.should == 500.0
      quote.mov_avg_200d.should == 600.0
      quote.traded_quantity.should == 5000.0

    end

  end
end