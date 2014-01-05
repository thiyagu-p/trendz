require 'spec_helper'

describe 'CorporateActionHandler' do

  shared_examples_for "a corporate action collection" do
    it 'should apply actions which are not applied upto current date' do
      stock = Stock.create!
      today = Date.today
      FactoryHelper.create_equity_holding(transaction: {stock: stock, quantity: 1, price: 10, date: today - 5, delivery: true})

      class_name = described_class.name.underscore
      past_action = create(class_name, stock: stock, ex_date: today - 2, applied: false)
      past_action_applied = create(class_name, stock: stock, ex_date: today - 1, applied: true)
      today_action = create(class_name, stock: stock, ex_date: today, applied: false)
      future_action = create(class_name, stock: stock, ex_date: today + 1, applied: false)

      Equity::CorporateActionHandler.apply_all

      described_class.find(past_action.id).applied?.should be_true
      described_class.find(past_action_applied.id).applied?.should be_true
      described_class.find(today_action.id).applied?.should be_true
      described_class.find(future_action.id).applied?.should_not be_true
    end
  end

  shared_examples_for "a corporate action" do
    it 'should apply pending action upto specified date' do
      stock = Stock.create!
      date = Date.parse('01/02/2013')
      FactoryHelper.create_equity_holding(transaction: {stock: stock, quantity: 1, price: 10, date: date - 10, delivery: true})

      class_name = described_class.name.underscore
      past_action = create(class_name, stock: stock, ex_date: date - 2, applied: false)
      on_day_action = create(class_name, stock: stock, ex_date: date, applied: false)
      future_action = create(class_name, stock: stock, ex_date: date + 1, applied: false)

      Equity::CorporateActionHandler.apply_pending_upto(stock, date)
      expect(described_class.find(past_action.id).transactions.size).to be(1)
      expect(described_class.find(on_day_action.id).transactions.size).to be > 0
      expect(described_class.find(future_action.id).transactions.size).to be(0)
    end
  end

  describe BonusAction do
    it_behaves_like "a corporate action collection"
    it_behaves_like "a corporate action" do
      transactions_class = :bonus_transactions
    end
  end
  describe DividendAction do
    it_behaves_like "a corporate action collection"
    it_behaves_like "a corporate action", :dividend_transactions
  end
  describe FaceValueAction do
    it_behaves_like "a corporate action collection"
    it_behaves_like "a corporate action", :face_value_transactions
  end
end