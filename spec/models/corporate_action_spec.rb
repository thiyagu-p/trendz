require 'spec_helper'

describe CorporateAction do

  describe 'future_actions_with_current_percentage' do
    it "should find future actions" do
      stock = create(:stock)
      EqQuote.create!(stock: stock, close: 100, date: Date.yesterday)
      action = create(:corporate_action_divident, stock: stock, ex_date: Date.today)
      future_actions = CorporateAction.future_actions_with_current_percentage
      future_actions.size.should == 1
      future_actions.first.should == action
    end

    it "should find current_percentage" do
      stock = create(:stock)
      EqQuote.create!(stock: stock, close: 1000, date: Date.yesterday)
      create(:corporate_action_divident, stock: stock, ex_date: Date.today)
      future_actions = CorporateAction.future_actions_with_current_percentage
      future_actions.first.parsed_data.first['current_percentage'] == 1.20
    end
    it "should ignore actions which doesn't have latest quote" do
      stock = create(:stock)
      create(:corporate_action_divident, stock: stock, ex_date: Date.today)
      future_actions = CorporateAction.future_actions_with_current_percentage
      future_actions.should be_empty
    end

    it "should ignore ignore-actions" do
      stock = create(:stock)
      EqQuote.create!(stock: stock, close: 100, date: Date.yesterday)
      create(:corporate_action_ignore, stock: stock, ex_date: Date.today)
      future_actions = CorporateAction.future_actions_with_current_percentage
      future_actions.should be_empty
    end
  end
end