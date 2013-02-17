require 'spec_helper'

describe BonusAction do

  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @params = {quantity: 100, price: 250, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
    @exdate = Date.parse('1/1/2012')
  end

  it 'should allocate bonus for specific stock' do
    create(:equity_buy, @params.merge(date: @exdate - 1))
    BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1).apply
    EquityTransaction.count.should == 2
  end

  it 'should allocate bonus for based on ratio of bonus and holding stock' do
    create(:equity_buy, @params.merge(date: @exdate - 1))
    BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 2).apply
    bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
    bonus_transaction.quantity.should == 100 / 5 * 2
  end


  it 'should allocate bonus specific to trading account' do
    create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
    new_trading_account = TradingAccount.create
    create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 200, trading_account: new_trading_account))

    BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply

    EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, @trading_account.id).quantity.should == 100 / 5 * 3
    EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, new_trading_account.id).quantity.should == 200 / 5 * 3
  end

  it 'should allocate bonus specific to portfolio' do
    create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
    new_portfolio = Portfolio.create
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
    create(:equity_buy, @params.merge(date: @exdate - 1))
    create(:equity_sell, @params.merge(date: @exdate - 1))

    expect {
      BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply
    }.to_not change { EquityTransaction.count }

  end

  it 'should have 0 price and brokerage' do
    create(:equity_buy, @params.merge(date: @exdate - 1))

    BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3).apply

    bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
    bonus_transaction.price.should be_zero
    bonus_transaction.brokerage.should be_zero
  end

  it 'should have rounded quantity' do
    create(:equity_buy, @params.merge(date: @exdate - 1))

    BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 15, bonus_qty: 1).apply

    bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
    bonus_transaction.quantity.should == 6
  end

  it 'should not create bonus transaction if quantity is zero' do
    create(:equity_buy, @params.merge(date: @exdate - 1))
    expect { BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 200, bonus_qty: 3).apply }.to_not change { EquityTransaction.count }
  end

end
