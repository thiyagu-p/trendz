require 'spec_helper'

describe MovingAverageCalculator do

  before(:all) do
    @stock = Stock.create!(:symbol => 'MyStock')
    @start_date = Date.parse('1/1/2010')
    250.times do |index|
      EqQuote.create!(:stock => @stock, :open => 100, :high => 1000, :low => 0.1, :close => index + 1, :date => @start_date + index)
    end
  end

  it 'should update 10 days moving average' do
    date = @start_date + 9
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_10d.to_f.should == 5.5

    date = @start_date + 10
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_10d.to_f.should == 6.5
  end

  it 'should update 50 days moving average' do
    date = @start_date + 49
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_50d.to_f.should == 25.5

    date = @start_date + 50
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_50d.to_f.should == 26.5
  end

  it 'should update 200 days moving average' do
    date = @start_date + 199
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_200d.to_f.should == 100.5

    date = @start_date + 201
    MovingAverageCalculator.update(date, @stock)
    EqQuote.find_by_stock_id_and_date(@stock.id, date).mov_avg_200d.to_f.should == 102.5
  end

end
