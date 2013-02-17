require 'spec_helper'

describe EquityBuy do

  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @date = Date.today
    @hash = {price: 120, quantity: 80, trading_account: @trading_account, portfolio: @portfolio, stock: @stock,
             date: @date, brokerage: 320}
  end

  describe 'find_holdings_on' do

    it "should find holdings of stock on a given day" do
      buy1 = EquityBuy.create(@hash.merge(quantity: 101))
      buy2 = EquityBuy.create(@hash.merge(quantity: 202))
      buy3 = EquityBuy.create(@hash.merge(quantity: 303))
      holdings = EquityBuy.find_holdings_on(@stock, @hash[:date], @trading_account, @portfolio)
      holdings.count.should == 3
      holdings.should =~ [buy1, buy2, buy3]
    end

    it "should handling partial holding and update holding qty" do
      buy = EquityBuy.create(@hash.merge(quantity: 101))
      sell = EquitySell.create(@hash.merge(quantity: 50))
      Equity::Trader.handle_new_transaction(buy)
      Equity::Trader.handle_new_transaction(sell)
      holdings = EquityBuy.find_holdings_on(@stock, @hash[:date], @trading_account, @portfolio)
      holdings.first.holding_qty.should == 51
    end

    it "should ignore future transactions while finding holdings" do
      Equity::Trader.handle_new_transaction(buy1 = EquityBuy.create(@hash.merge(quantity: 101, date: Date.today)))
      Equity::Trader.handle_new_transaction(buy2 = EquityBuy.create(@hash.merge(quantity: 202, date: Date.tomorrow)))
      Equity::Trader.handle_new_transaction(sell1 = EquitySell.create(@hash.merge(quantity: 100, date: Date.tomorrow + 1)))
      Equity::Trader.handle_new_transaction(sell2 = EquitySell.create(@hash.merge(quantity: 2, date: Date.tomorrow + 2)))

      EquityBuy.find_holdings_on(@stock, Date.today, @trading_account, @portfolio).should =~ [buy1]
      EquityBuy.find_holdings_on(@stock, Date.tomorrow, @trading_account, @portfolio).should =~ [buy1, buy2]
      EquityBuy.find_holdings_on(@stock, Date.tomorrow + 1, @trading_account, @portfolio).should == [buy1, buy2]
      EquityBuy.find_holdings_on(@stock, Date.tomorrow + 2, @trading_account, @portfolio).should == [buy2]
    end

    it "should ignore other stock holdings while finding holdings for a specific stock" do
      buy1 = EquityBuy.create(@hash.merge(quantity: 101))
      EquityBuy.create(@hash.merge(quantity: 202, stock: create(:stock)))
      EquityBuy.find_holdings_on(@stock, Date.today, @trading_account, @portfolio).should =~ [buy1]
    end

    it "should filter by given trading account" do
      buy1 = EquityBuy.create(@hash.merge(quantity: 101))
      new_trading_account = create(:trading_account)
      buy2 = EquityBuy.create(@hash.merge(quantity: 202, trading_account: new_trading_account))
      EquityBuy.find_holdings_on(@stock, Date.today, @trading_account, @portfolio).should == [buy1]
      EquityBuy.find_holdings_on(@stock, Date.today, new_trading_account, @portfolio).should == [buy2]
    end

    it "should filter by given portfolio account" do
      buy1= EquityBuy.create(@hash.merge(quantity: 101))
      new_portfolio = create(:portfolio)
      buy2= EquityBuy.create(@hash.merge(quantity: 202, portfolio: new_portfolio))
      EquityBuy.find_holdings_on(@stock, Date.today, @trading_account, @portfolio).should == [buy1]
      EquityBuy.find_holdings_on(@stock, Date.today, @trading_account, new_portfolio).should == [buy2]
    end
  end

  describe 'find_holding_quantity' do

    it "should find holding qty of stock on a given day" do
      EquityBuy.create(@hash.merge(quantity: 101))
      EquityBuy.create(@hash.merge(quantity: 202))
      EquityBuy.create(@hash.merge(quantity: 303))
      EquityBuy.find_holding_quantity(@stock, @hash[:date], @trading_account, @portfolio).should == (101+202+303)
    end

    it "should ignore sold quantity while finding holding qty" do
      buy = EquityBuy.create(@hash.merge(quantity: 101))
      sell = EquitySell.create(@hash.merge(quantity: 50))
      Equity::Trader.handle_new_transaction(buy)
      Equity::Trader.handle_new_transaction(sell)
      EquityBuy.find_holding_quantity(@stock, @hash[:date], @trading_account, @portfolio).should == (101 - 50)
    end

    it "should ignore future transactions while finding holding qty" do
      buy1 = EquityBuy.create(@hash.merge(quantity: 101, date: Date.today))
      buy2 = EquityBuy.create(@hash.merge(quantity: 202, date: Date.tomorrow))
      sell1 = EquitySell.create(@hash.merge(quantity: 100, date: Date.tomorrow + 1))
      Equity::Trader.handle_new_transaction(buy1)
      Equity::Trader.handle_new_transaction(buy2)
      Equity::Trader.handle_new_transaction(sell1)

      EquityBuy.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityBuy.find_holding_quantity(@stock, Date.tomorrow, @trading_account, @portfolio).should == (101 + 202)
      EquityBuy.find_holding_quantity(@stock, Date.tomorrow + 1, @trading_account, @portfolio).should == (101 + 202 - 100)
    end

    it "should ignore other stock holdings while finding holding qty for a specific stock" do
      EquityBuy.create(@hash.merge(quantity: 101))
      EquityBuy.create(@hash.merge(quantity: 202, stock: create(:stock)))
      EquityBuy.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
    end

    it "should filter by given trading account" do
      EquityBuy.create(@hash.merge(quantity: 101))
      new_trading_account = create(:trading_account)
      EquityBuy.create(@hash.merge(quantity: 202, trading_account: new_trading_account))
      EquityBuy.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityBuy.find_holding_quantity(@stock, Date.today, new_trading_account, @portfolio).should == 202
    end

    it "should filter by given portfolio account" do
      EquityBuy.create(@hash.merge(quantity: 101))
      new_portfolio = create(:portfolio)
      EquityBuy.create(@hash.merge(quantity: 202, portfolio: new_portfolio))
      EquityBuy.find_holding_quantity(@stock, Date.today, @trading_account, @portfolio).should == 101
      EquityBuy.find_holding_quantity(@stock, Date.today, @trading_account, new_portfolio).should == 202
    end

  end

  describe 'apply_face_value_change' do
    it 'should apply conversion ration on price and quantity' do
      buy = EquityBuy.create!(@hash)
      conversion_factor = 0.2
      buy.apply_face_value_change(conversion_factor, @date + 1)
      buy.price.should == 120 * conversion_factor
      buy.quantity.should == 80 * conversion_factor
    end

    it 'should split holding vs sold into separate transaction' do
      buy = EquityBuy.create!(@hash)
      buy.holding_qty = 42
      expect {buy.apply_face_value_change(0.2, @date + 1)}.to change {EquityBuy.count}.by(1)
    end

    it 'should have original price, sold quantity and proportionate brokerage for sold transaction' do
      buy = EquityBuy.create!(@hash)
      holding_qty = 42
      conversion_factor = 0.2
      buy.holding_qty = holding_qty
      buy.apply_face_value_change(conversion_factor, @date + 1)
      buy.price.should == 120
      buy.quantity.should == (80 - holding_qty)
      buy.brokerage.should == 320 / 80 * (80 - holding_qty)
    end

    it 'should have new price, new holding quantity and proportionate brokerage for holding transaction' do
      buy = EquityBuy.create!(@hash)
      holding_qty = 42
      conversion_factor = 0.2
      buy.holding_qty = holding_qty

      buy.apply_face_value_change(conversion_factor, @date + 1)
      new_buy = EquityBuy.where("id <> #{buy.id}").first
      new_buy.price.should == 120.0 * conversion_factor
      new_buy.quantity.should == (buy.holding_qty / conversion_factor).to_i
      new_buy.brokerage.should == 320 / 80 * holding_qty
      new_buy.date.should == buy.date
    end

    it 'should update future sales to point to holding transaction' do
      exdate = @date + 1
      buy = EquityBuy.create!(@hash)
      sell_past = create(:equity_sell, @hash.merge(date: exdate - 1, quantity: 2))
      sell_future = create(:equity_sell, @hash.merge(date: exdate, quantity: 1))
      trade1 = EquityTrade.create!(equity_buy: buy, equity_sell: sell_past, quantity: 2)
      trade2 = EquityTrade.create!(equity_buy: buy, equity_sell: sell_future, quantity: 1)

      buy.holding_qty = 78

      buy.apply_face_value_change(0.2, @date)

      new_transaction = EquityBuy.where('id <> ?', buy.id).first
      EquityTrade.find_by_id_and_equity_sell_id(trade1.id, sell_past.id).equity_buy_id.should == buy.id
      EquityTrade.find_by_id_and_equity_sell_id(trade2.id, sell_future.id).equity_buy_id.should == new_transaction.id
    end

  end
end
