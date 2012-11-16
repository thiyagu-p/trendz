require 'spec_helper'

describe EquityTransaction do
  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @hash = {price: 1, quantity: 1, trading_account: @trading_account, portfolio: @portfolio, stock: @stock,
             action: EquityTransaction::BUY, date: Date.today}
  end

  describe "validation" do
    it "should validate presence of mandatory attributes" do
      [:price, :stock, :trading_account, :portfolio, :date].each do |attribute|
        EquityTransaction.new(@hash.except(attribute)).should_not be_valid
        EquityTransaction.new(@hash).should be_valid
      end
    end

    it "should validate quantity greater than 0" do
      EquityTransaction.new(@hash.except(:quantity)).should_not be_valid
      EquityTransaction.new(@hash.merge(quantity: 0)).should_not be_valid
      EquityTransaction.new(@hash).should be_valid
    end

    it "should allow only buy/sell action" do
      EquityTransaction.new(@hash.except(:action)).should_not be_valid
      EquityTransaction.new(@hash.merge(action: 'some')).should_not be_valid
      EquityTransaction.new(@hash.merge(action: EquityTransaction::BUY)).should be_valid
      EquityTransaction.new(@hash.merge(action: EquityTransaction::SELL)).should be_valid
    end
  end

  it "should identify buy transaction" do
    create(:equity_transaction, action: EquityTransaction::BUY).buy?.should be_true
    create(:equity_transaction, action: EquityTransaction::SELL).buy?.should be_false
  end

  describe "find_holding_quantity" do

    it "should find holding qty of stock on a given day" do
      EquityTransaction.create(@hash.merge(quantity: 101))
      EquityTransaction.create(@hash.merge(quantity: 202))
      EquityTransaction.create(@hash.merge(quantity: 303))
      EquityTransaction.find_holding_quantity(@stock, @hash[:date], @trading_account, @portfolio).should == (101+202+303)
    end

    it "should ignore sold quantity while finding holding qty" do
      EquityTransaction.create(@hash.merge(quantity: 101))
      EquityTransaction.create(@hash.merge(quantity: 50, action: EquityTransaction::SELL))
      EquityTransaction.find_holding_quantity(@stock, @hash[:date], @trading_account, @portfolio).should == (101 - 50)
    end

    it "should ignore future transactions while finding holding qty" do
      EquityTransaction.create(@hash.merge(quantity: 101, date: Date.today))
      EquityTransaction.create(@hash.merge(quantity: 202, date: Date.tomorrow))
      EquityTransaction.create(@hash.merge(quantity: 100, date: Date.tomorrow + 1, action: EquityTransaction::SELL))
      EquityTransaction.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityTransaction.find_holding_quantity(@stock, Date.tomorrow, @trading_account, @portfolio).should == (101 + 202)
      EquityTransaction.find_holding_quantity(@stock, Date.tomorrow + 1, @trading_account, @portfolio).should == (101 + 202 - 100)
    end

    it "should ignore other stock holdings while finding holding qty for a specific stock" do
      EquityTransaction.create(@hash.merge(quantity: 101))
      EquityTransaction.create(@hash.merge(quantity: 202, stock: create(:stock)))
      EquityTransaction.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
    end

    it "should filter by given trading account" do
      EquityTransaction.create(@hash.merge(quantity: 101))
      new_trading_account = create(:trading_account)
      EquityTransaction.create(@hash.merge(quantity: 202, trading_account: new_trading_account))
      EquityTransaction.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityTransaction.find_holding_quantity(@stock, Date.today, new_trading_account, @portfolio).should == 202
    end

    it "should filter by given portfolio account" do
      EquityTransaction.create(@hash.merge(quantity: 101))
      new_portfolio = create(:portfolio)
      EquityTransaction.create(@hash.merge(quantity: 202, portfolio: new_portfolio))
      EquityTransaction.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityTransaction.find_holding_quantity(@stock, Date.today, @trading_account, new_portfolio).should == 202
    end

  end
end
