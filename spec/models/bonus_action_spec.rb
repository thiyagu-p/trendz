require 'spec_helper'

describe BonusAction do

  context 'portfolio' do
    before :each do
      @trading_account = create(:trading_account)
      @portfolio = create(:portfolio)
      @stock = create(:stock)
      @params = {quantity: 100, price: 250, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
      @exdate = Date.parse('1/1/2012')
    end

    it 'should allocate bonus for specific stock' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1).apply
      EquityTransaction.count.should == 2
    end

    it 'should not allocate bonus for non delivery stock' do
      create(:equity_buy, @params.merge(date: @exdate - 1, delivery: false))
      bonus = BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1)
      expect{bonus.apply}.to_not change{EquityTransaction.count}
    end

    it 'should set applied' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      bonus = BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1)
      expect{bonus.apply}.to change{EquityTransaction.count}.by(1)
      bonus.applied?.should be_true
    end

    it 'should set skip already applied' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      bonus = BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1)
      bonus.apply
      bonus.update_attribute(:applied, false)
      expect{bonus.apply}.to_not change{EquityTransaction.count}
    end

    it 'should allocate bonus for based on ratio of bonus and holding stock' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 2).apply
      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.quantity.should == 100 / 5 * 2
    end


    it 'should allocate bonus specific to trading account' do
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
      new_trading_account = create(:trading_account)
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 200, trading_account: new_trading_account))

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply

      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, @trading_account.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, new_trading_account.id).quantity.should == 200 / 5 * 3
    end

    it 'should allocate bonus specific to portfolio' do
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
      new_portfolio = create(:portfolio)
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 200, portfolio: new_portfolio))

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply

      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, @portfolio.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, new_portfolio.id).quantity.should == 200 / 5 * 3
    end

    it 'should not allocate bonus for stocks purchased on ex-date' do
      create(:equity_buy, @params.merge(date: @exdate))

      expect {
        BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply
      }.to_not change { EquityTransaction.count }
    end

    it 'should not allocate bonus for stocks purchased after ex-date' do
      create(:equity_buy, @params.merge(date: @exdate + 1))

      expect {
        BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply
      }.to_not change { EquityTransaction.count }

    end

    it 'should not allocate bonus for non holding transaction on record date' do
      Equity::Trader.handle_new_transaction(create(:equity_buy, @params.merge(date: @exdate - 1)))
      Equity::Trader.handle_new_transaction(create(:equity_sell, @params.merge(date: @exdate - 1)))

      expect {
        BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply
      }.to_not change { EquityTransaction.count }

    end

    it 'should have 0 price and brokerage' do
      create(:equity_buy, @params.merge(date: @exdate - 1))

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply

      bonus_transaction = EquityTransaction.find_by(stock_id: @stock.id, date: @exdate)
      bonus_transaction.price.should be_zero
      bonus_transaction.brokerage.should be_zero
    end

    it 'should have rounded quantity' do
      create(:equity_buy, @params.merge(date: @exdate - 1))

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 15, bonus_qty: 1).apply

      bonus_transaction = EquityTransaction.find_by(stock_id: @stock.id, date: @exdate)
      bonus_transaction.quantity.should == 6
    end

    it 'should not create bonus transaction if quantity is zero' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      expect { BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 200, bonus_qty: 3).apply }.to_not change { EquityTransaction.count }
    end

    it 'should create bonus transcation mapping' do
      buy1 = create(:equity_buy, @params.merge(date: @exdate - 1))
      buy2 = create(:equity_buy, @params.merge(date: @exdate - 1))

      bonus_action = BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 15, bonus_qty: 1)
      bonus_action.apply

      bonus_transactions = BonusTransaction.where(bonus_action_id: bonus_action.id).to_a
      expect(bonus_transactions.collect(&:source_transaction_id)).to match_array([buy1.id, buy2.id])
    end

    it 'should update holding quantity' do
      create(:equity_buy, @params.merge(date: @exdate - 1))

      bonus_action = BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 15, bonus_qty: 1)
      bonus_action.apply

      bonus = bonus_action.bonus.first
      holding = EquityHolding.find_by(equity_transaction_id: bonus.id)
      holding.quantity.should == bonus.quantity
    end
  end

  context 'quotes' do

    before :each do
      @stock = Stock.create
      @exdate = Date.parse('1/1/2012')
      @holding_qty = 2.0
      @bonus_qty = 1.0
    end

    it 'equity' do
      EqQuote.expects(:apply_factor).with(@stock, @holding_qty/(@holding_qty+@bonus_qty), @exdate)

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: @holding_qty, bonus_qty: @bonus_qty).apply
    end

    it 'futures' do
      FoQuote.expects(:apply_factor).with(@stock, @holding_qty/(@holding_qty+@bonus_qty), @exdate)

      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: @holding_qty, bonus_qty: @bonus_qty).apply
    end
  end
end
