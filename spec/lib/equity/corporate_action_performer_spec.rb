require 'spec_helper'

describe 'CorporateActionPerformer' do

  shared_examples_for "a corporate action collection" do
    it 'should apply actions which are not applied upto current date' do
      stock = Stock.create!
      today = Date.today
      FactoryHelper.create_equity_holding(transaction: {stock: stock, quantity: 1, price: 10, date: today - 5})

      class_name = described_class.name.underscore
      past_action = create(class_name, stock: stock, ex_date: today - 2, applied: false)
      past_action_applied = create(class_name, stock: stock, ex_date: today - 1, applied: true)
      today_action = create(class_name, stock: stock, ex_date: today, applied: false)
      future_action = create(class_name, stock: stock, ex_date: today + 1, applied: false)

      Equity::CorporateActionPerformer.perform

      described_class.find(past_action.id).applied?.should be_true
      described_class.find(past_action_applied.id).applied?.should be_true
      described_class.find(today_action.id).applied?.should be_true
      described_class.find(future_action.id).applied?.should_not be_true
    end
  end

  describe BonusAction do
    it_behaves_like "a corporate action collection"
  end
  describe DividendAction do
    it_behaves_like "a corporate action collection"
  end
  describe FaceValueAction do
    it_behaves_like "a corporate action collection"
  end
end