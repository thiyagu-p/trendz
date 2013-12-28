require 'spec_helper'

describe CorporateActionPerformer do

  it 'should apply all bonus actions which are not applied upto current date' do
    stock = Stock.create!
    today = Date.today
    FactoryHelper.create_equity_holding(transaction: {stock: stock, quantity: 1, price: 10, date: today - 5})

    past_action = create(:bonus_action, stock: stock, ex_date:today - 2, applied: false)
    past_action_applied = create(:bonus_action, stock: stock, ex_date:today - 1, applied: true)
    today_action = create(:bonus_action, stock: stock, ex_date:today, applied: false)
    future_action = create(:bonus_action, stock: stock, ex_date:today + 1, applied: false)

    CorporateActionPerformer.perform

    EquityBuy.where(stock_id: stock).where(date: past_action.ex_date).first.quantity.should_not be_nil
    EquityBuy.where(stock_id: stock).where(date: past_action_applied.ex_date).first.should be_nil
    EquityBuy.where(stock_id: stock).where(date: today_action.ex_date).first.quantity.should_not be_nil
    EquityBuy.where(stock_id: stock).where(date: future_action.ex_date).first.should be_nil

    BonusAction.find(past_action.id).applied?.should be_true
    BonusAction.find(past_action_applied.id).applied?.should be_true
    BonusAction.find(today_action.id).applied?.should be_true
    BonusAction.find(future_action.id).applied?.should_not be_true
  end

  it 'should apply all face values actions which are not applied upto current date' do
    stock = Stock.create!
    today = Date.today
    FactoryHelper.create_equity_holding(transaction: {stock: stock, quantity: 100, price: 10, date: today - 5})

    past_action = create(:face_value_action, stock: stock, ex_date:today - 2, applied: false)
    past_action_applied = create(:face_value_action, stock: stock, ex_date:today - 1, applied: true)
    today_action = create(:face_value_action, stock: stock, ex_date:today, applied: false)
    future_action = create(:face_value_action, stock: stock, ex_date:today + 1, applied: false)

    CorporateActionPerformer.perform

    FaceValueAction.find(past_action.id).applied?.should be_true
    FaceValueAction.find(past_action_applied.id).applied?.should be_true
    FaceValueAction.find(today_action.id).applied?.should be_true
    FaceValueAction.find(future_action.id).applied?.should_not be_true
  end

  it 'should apply all dividend actions which are not applied upto current date' do
   pending
  end

end