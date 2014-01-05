require 'spec_helper'

describe EquityTransactionsController do

  describe :create do
    before :each do
      @trading_account = create(:trading_account)
      @portfolio = create(:portfolio)
      @stock = create(:stock)
      @hash = {price: BigDecimal.new("1.1"), quantity: 2, trading_account_id: @trading_account.id, portfolio_id: @portfolio.id, stock_id: @stock.id,
               type: EquityTransaction::BUY, date: Date.today}
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
      expect{post :create, :equity_transaction => {}}.to raise_error(ActionController::ParameterMissing)
    end
  end
end
