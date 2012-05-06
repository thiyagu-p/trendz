require 'spec_helper'

describe EquityTransaction do
  describe "validation" do
    before :each do
      @trading_account = TradingAccount.create
      @portfolio = Portfolio.create
      @stock = Stock.create
      @hash = {price: 1, quantity: 1, trading_account: @trading_account, portfolio: @portfolio, stock: @stock,
               action: EquityTransaction::BUY, date: Date.today}
    end

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
end
