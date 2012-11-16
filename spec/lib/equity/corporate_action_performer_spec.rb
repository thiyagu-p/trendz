require 'spec_helper'

describe Equity::CorporateActionPerformer do

  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @params = {quantity: 100, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: false}
    @exdate = Date.parse('1/1/2012')
  end

  describe 'bonus' do

    it 'should allocate bonus for specific stock' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))
      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 1, bonus: 1)
      EquityTransaction.count.should == 2
    end

    it 'should allocate bonus for based on ratio of bonus and holding stock' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))
      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 2)
      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.quantity.should == 100 / 5 * 2
    end


    it 'should allocate bonus specific to trading account' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1, quantity: 100))
      new_trading_account = TradingAccount.create
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1, quantity: 200, trading_account: new_trading_account))

      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)

      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, @trading_account.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, new_trading_account.id).quantity.should == 200 / 5 * 3
    end

    it 'should allocate bonus specific to portfolio' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1, quantity: 100))
      new_portfolio = Portfolio.create
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1, quantity: 200, portfolio: new_portfolio))

      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)

      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, @portfolio.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, new_portfolio.id).quantity.should == 200 / 5 * 3
    end

    it 'should not allocate bonus for stocks purchased on ex-date' do
      create(:buy_equity_transaction, @params.merge(date: @exdate))

      expect {
        Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)
      }.to_not change { EquityTransaction.count }
    end

    it 'should not allocate bonus for stocks purchased after ex-date' do
      create(:buy_equity_transaction, @params.merge(date: @exdate + 1))

      expect {
        Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)
      }.to_not change { EquityTransaction.count }

    end

    it 'should not allocate bonus for non holding transaction on record date' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))
      create(:sell_equity_transaction, @params.merge(date: @exdate - 1))

      expect {
        Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)
      }.to_not change { EquityTransaction.count }

    end

    it 'should have 0 price and brokerage' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))

      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 5, bonus: 3)

      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.price.should be_zero
      bonus_transaction.brokerage.should be_zero
    end

    it 'should have rounded quantity' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))

      Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 15, bonus: 1)

      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.quantity.should == 6
    end

    it 'should not create bonus transaction if quantity is zero' do
      create(:buy_equity_transaction, @params.merge(date: @exdate - 1))
      expect { Equity::CorporateActionPerformer.apply(create :corporate_action_bonus, stock: @stock, ex_date: @exdate, holding: 200, bonus: 3) }.to_not change { EquityTransaction.count }
    end

  end
end



