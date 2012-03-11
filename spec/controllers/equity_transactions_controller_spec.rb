require 'spec_helper'

describe EquityTransactionsController do

  describe :create do
    before :each do
      @trading_account = TradingAccount.create
      @portfolio = Portfolio.create
      @stock = Stock.create
      @hash = {price: 1, quantity: 1, trading_account_id: @trading_account.id, portfolio_id: @portfolio.id, stock_id: @stock.id,
               action: EquityTransaction::BUY, date: Date.today}
    end

    it "should create transaction" do
      expect {
        post :create, :equity_transaction => @hash
      }.to change(EquityTransaction, :count).by(1)

      equity_transaction = EquityTransaction.first
      @hash.each_pair do |key, value|
        equity_transaction.send(key).should == value
      end
    end

    it "should render ok" do
      post :create, :equity_transaction => @hash
      response.status == 200
    end

    it "should handle error" do
      post :create, :equity_transaction => {}
      response.status == :unprocessable_entity
    end
  end
end
