require 'spec_helper'

describe EquityTransaction do
  before :each do
    @trading_account = create(:trading_account)
    @portfolio = create(:portfolio)
    @stock = create(:stock)
    @hash = {price: 1, quantity: 1, trading_account: @trading_account, portfolio: @portfolio, stock: @stock,
             date: Date.today}
  end

  describe "validation" do
    it "should validate presence of mandatory attributes" do
      [:price, :stock, :trading_account, :portfolio, :date].each do |attribute|
        EquityBuy.new(@hash.except(attribute)).should_not be_valid
        EquitySell.new(@hash.except(attribute)).should_not be_valid
      end
    end

    it "should validate quantity greater than 0" do
      EquityBuy.new(@hash.except(:quantity)).should_not be_valid
      EquityBuy.new(@hash.merge(quantity: 0)).should_not be_valid
      EquitySell.new(@hash.merge(quantity: 0)).should_not be_valid
    end

    it "should allow only buy/sell action" do
      EquityTransaction.new(@hash).should_not be_valid
      EquityBuy.new(@hash).should be_valid
      EquitySell.new(@hash).should be_valid
    end
  end

end
