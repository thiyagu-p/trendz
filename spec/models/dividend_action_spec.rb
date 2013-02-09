require 'spec_helper'

describe DividendAction do
  before :each do
    @stock = create(:stock, face_value: 5)
  end

  describe 'future_actions_with_current_percentage' do
    it "should find future actions" do
      EqQuote.create!(stock: @stock, close: 100, date: Date.yesterday)
      dividend = DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.size.should == 1
      dividends.first.should == dividend
    end

    it "should find current_percentage" do
      EqQuote.create!(stock: @stock, close: 100, date: Date.yesterday)
      DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.first.current_percentage == 1.20
    end
    it "should ignore actions which doesn't have latest quote" do
      DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.empty?.should be_true
    end
  end
end