require 'spec_helper'

describe Equity::Trader do

  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @params = {quantity: 100, transaction: {portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: false}}
  end

  describe 'holding' do

    it 'should create holding on buy transaction' do
      buy = create(:equity_buy, @params[:transaction])
      expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityHolding, :count).by(1)
      EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == buy.quantity
    end

    it 'should create negative holding on sell transaction' do
      sell = create(:equity_sell, @params[:transaction])
      expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityHolding, :count).by(1)
      EquityHolding.find_by_equity_transaction_id(sell.id).quantity.should == -sell.quantity
    end
  end

  describe 'trade' do
    describe 'sell after buy' do

      it "should create trade and update holding for matched buy and sell" do
        buy = FactoryHelper.create_equity_holding(@params).equity_transaction
        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity - 10))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)

        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
        EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == (buy.quantity - sell.quantity)
      end

      it "should remove holding if there is complete match of buy and sell quantity" do
        buy = FactoryHelper.create_equity_holding(@params).equity_transaction
        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityHolding, :count).by(-1)
      end

      it "should handle multiple buys to single sell" do
        buy1 = FactoryHelper.create_equity_holding(@params).equity_transaction
        buy2 = FactoryHelper.create_equity_holding(@params).equity_transaction

        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy1.quantity + buy2.quantity))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(2)

        [buy1, buy2].each { |buy|
          EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == buy.quantity
        }

        EquityHolding.count.should == 0
      end

      it "should handle over sold" do
        buy = FactoryHelper.create_equity_holding(@params).equity_transaction
        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity + 10))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)

        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == buy.quantity
        EquityHolding.find_by_equity_transaction_id(buy.id).should be_nil
        EquityHolding.find_by_equity_transaction_id(sell.id).quantity.should == (buy.quantity - sell.quantity)
      end

      it "should handle multiple sell from a single buy" do
        buy = FactoryHelper.create_equity_holding(@params).equity_transaction

        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity / 2))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
        EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == buy.quantity - sell.quantity

        sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity / 2))
        expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
        EquityHolding.find_by_equity_transaction_id(buy.id).should be_nil
      end
    end

    describe 'buy after sell' do

      before :each do
        @params.merge!(quantity: -100)
      end

      it "should create trade and update holding for matched buy and sell" do
        sell = FactoryHelper.create_equity_holding(@params).equity_transaction
        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell.quantity - 10))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityTrade, :count).by(1)

        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == buy.quantity
        EquityHolding.find_by_equity_transaction_id(sell.id).quantity.should == -(sell.quantity - buy.quantity)
      end

      it "should remove holding if there is complete match of buy and sell quantity" do
        sell = FactoryHelper.create_equity_holding(@params).equity_transaction
        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell.quantity))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityHolding, :count).by(-1)
      end

      it "should handle multiple sells to single buy" do
        sell1 = FactoryHelper.create_equity_holding(@params).equity_transaction
        sell2 = FactoryHelper.create_equity_holding(@params).equity_transaction

        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell1.quantity + sell2.quantity))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityTrade, :count).by(2)

        [sell1, sell2].each { |sell|
          EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
        }

        EquityHolding.count.should == 0
      end

      it "should handle over bought" do
        sell = FactoryHelper.create_equity_holding(@params).equity_transaction
        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell.quantity + 10))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityTrade, :count).by(1)

        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
        EquityHolding.find_by_equity_transaction_id(sell.id).should be_nil
        EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == (buy.quantity - sell.quantity)
      end

      it "should handle multiple buy from a single sell" do
        sell = FactoryHelper.create_equity_holding(@params).equity_transaction

        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell.quantity / 2))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityTrade, :count).by(1)
        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == buy.quantity
        EquityHolding.find_by_equity_transaction_id(sell.id).quantity.should == buy.quantity - sell.quantity

        buy = create(:equity_buy, @params[:transaction].merge(quantity: sell.quantity / 2))
        expect { Equity::Trader.handle_new_transaction(buy) }.to change(EquityTrade, :count).by(1)
        EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == buy.quantity
        EquityHolding.find_by_equity_transaction_id(sell.id).should be_nil
      end
    end
  end

  it "should match multiple buy and multiple sell" do
    #Holding 20, Sell 10
    buy = FactoryHelper.create_equity_holding(@params.merge(quantity: 20)).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: 10))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
    EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == 10

    #Holding 10, Sell 5
    sell = create(:equity_sell, @params[:transaction].merge(quantity: 5))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == sell.quantity
    EquityHolding.find_by_equity_transaction_id(buy.id).quantity.should == 5

    #Holding 5,  buy 10
    buy2 = create(:equity_buy, @params[:transaction].merge(quantity: 10))
    expect { Equity::Trader.handle_new_transaction(buy2) }.to change(EquityTrade, :count).by(0)
    EquityHolding.find_by_equity_transaction_id(buy2.id).quantity.should == 10

    #Holding 5 + 10,  sell 10
    sell = create(:equity_sell, @params[:transaction].merge(quantity: 10))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(2)
    EquityHolding.find_by_equity_transaction_id(buy.id).should be_nil
    EquityHolding.find_by_equity_transaction_id(buy2.id).quantity.should == 5
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy.id, sell.id).quantity.should == 5
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy2.id, sell.id).quantity.should == 5

    #Holding 5,  sell 10
    sell1 = create(:equity_sell, @params[:transaction].merge(quantity: 10))
    expect { Equity::Trader.handle_new_transaction(sell1) }.to change(EquityTrade, :count).by(1)
    EquityHolding.find_by_equity_transaction_id(buy2.id).should be_nil
    EquityHolding.find_by_equity_transaction_id(sell1.id).quantity.should == -5
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy2.id, sell1.id).quantity.should == 5

    #Holding -5,  sell 10
    sell2 = create(:equity_sell, @params[:transaction].merge(quantity: 10))
    expect { Equity::Trader.handle_new_transaction(sell2) }.to change(EquityTrade, :count).by(0)
    EquityHolding.find_by_equity_transaction_id(sell1.id).quantity.should == -5
    EquityHolding.find_by_equity_transaction_id(sell2.id).quantity.should == -10

    #Holding -15,  buy 15
    buy3 = create(:equity_buy, @params[:transaction].merge(quantity: 15))
    expect { Equity::Trader.handle_new_transaction(buy3) }.to change(EquityTrade, :count).by(2)
    EquityHolding.find_by_equity_transaction_id(sell1.id).should be_nil
    EquityHolding.find_by_equity_transaction_id(sell2.id).should be_nil
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy3.id, sell1.id).quantity.should == 5
    EquityTrade.find_by_equity_buy_id_and_equity_sell_id(buy3.id, sell2.id).quantity.should == 10

  end

  it "should match buy and sell only within same trading account" do
    buy = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity, trading_account: TradingAccount.create))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(0)
  end

  it "should match buy and sell only within same portfolio account" do
    buy = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity, portfolio: Portfolio.create))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(0)
  end

  it "should match buy and sell of delivery trade ignoring day trade" do
    @params = {quantity: 100, transaction: {portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}}
    buy = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity, delivery: false))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(0)

    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
  end

  it "should match buy and sell of day trade ignoring delivery trade" do
    buy = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity, delivery: true))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(0)

    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(1)
  end

  it "should match buy and sell based on earliest date first" do
    @params = {quantity: 100, transaction: {portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true, date: '2/1/2012'}}
    buy1 = FactoryHelper.create_equity_holding(@params).equity_transaction
    @params[:transaction].merge!(date: '1/1/2012')
    buy2 = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy1.quantity, date: '3/1/2012'))
    Equity::Trader.handle_new_transaction(sell)
    EquityHolding.find_by_equity_transaction_id(buy2.id).should be_nil
  end

  it "should match only with previous transactions, ignoring future to current transaction" do
    @params = {quantity: 100, transaction: {portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true, date: '2/1/2012'}}
    buy = FactoryHelper.create_equity_holding(@params).equity_transaction
    sell = create(:equity_sell, @params[:transaction].merge(quantity: buy.quantity, date: '1/1/2012'))
    expect { Equity::Trader.handle_new_transaction(sell) }.to change(EquityTrade, :count).by(0)
  end
end

