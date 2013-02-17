require 'spec_helper'

describe FaceValueAction do

  it 'should calculate conversion ration' do
    FaceValueAction.new(from: 1, to: 10).conversion_ration.should == 10
    FaceValueAction.new(from: 10, to: 2).conversion_ration.should == 0.2
    FaceValueAction.new(from: 10, to: 5).conversion_ration.should == 0.5
    FaceValueAction.new(from: 3, to: 1).conversion_ration.should == 0.33
  end

  describe :apply do

    before :each do
      @trading_account = TradingAccount.create
      @portfolio = Portfolio.create
      @stock = Stock.create
      @exdate = Date.parse('1/1/2012')
      @params = {quantity: 100, price: 250, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
    end


    it 'should update quantity and price based on face value impact' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      (action = FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2)).apply

      EquityTransaction.count.should == 1
      transaction = EquityTransaction.first
      face_value_change_ratio = action.to.to_f / action.from.to_f
      transaction.price.to_f.should == @params[:price] * face_value_change_ratio
      transaction.quantity.to_f.should == @params[:quantity] * face_value_change_ratio
    end

    describe :partial_sale do

      before :each do
        @params = {quantity: 100, price: 250, brokerage: 200, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
        Equity::Trader.handle_new_transaction(@buy = create(:equity_buy, @params.merge(date: @exdate - 1)))
        Equity::Trader.handle_new_transaction(@sell = create(:equity_sell, @params.merge(date: @exdate - 1, quantity: 49)))
        @action = FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2)
      end

      it 'should separate sold and holding into separate transaction' do

        expect { @action.apply }.to change { EquityTransaction.count }.by(1)
      end

      it 'should keep sold transaction with original price, sold quantity and proportionate brokerage' do
        @action.apply

        sold_transaction = EquityBuy.find(@buy.id)
        sold_transaction.price.should == @params[:price]
        sold_transaction.quantity.should == @sell.quantity
        sold_transaction.brokerage.should == 200.0/100.0*@sell.quantity
        sold_transaction.portfolio.should == @params[:portfolio]
        sold_transaction.trading_account.should == @params[:trading_account]
        sold_transaction.stock.should == @params[:stock]
        sold_transaction.delivery.should == @params[:delivery]
      end

      it 'should update holding transaction with new price, holding quantity and proportionate brokerage' do
        @action.apply

        new_transaction = EquityBuy.where('id <> ?', @buy.id).first
        new_transaction.price.should == @params[:price] * @action.conversion_ration
        new_transaction.quantity.should == ((100 - @sell.quantity) / @action.conversion_ration).round(2)
        new_transaction.brokerage.to_f.should == 200.0/100.0*(100 - @sell.quantity)
        new_transaction.portfolio.should == @params[:portfolio]
        new_transaction.trading_account.should == @params[:trading_account]
        new_transaction.stock.should == @params[:stock]
        new_transaction.delivery.should == @params[:delivery]
      end

      it 'should map future trade to point to new transaction' do
        Equity::Trader.handle_new_transaction(@sell2 = create(:equity_sell, @params.merge(date: @exdate, quantity: 2)))
        Equity::Trader.handle_new_transaction(@sell3 = create(:equity_sell, @params.merge(date: @exdate, quantity: 1)))

        @action.apply

        new_transaction = EquityBuy.where('id <> ?', @buy.id).first
        EquityTrade.find_by_equity_sell_id(@sell).equity_buy_id.should == @buy.id
        EquityTrade.find_by_equity_sell_id(@sell2).equity_buy_id.should == new_transaction.id
        EquityTrade.find_by_equity_sell_id(@sell3).equity_buy_id.should == new_transaction.id
      end
    end

    it 'should ignore future buy' do
      create(:equity_buy, @params.merge(date: @exdate))
      FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2).apply
      EquityTransaction.count.should == 1
      transaction = EquityTransaction.first
      transaction.price.to_f.should == @params[:price]
      transaction.quantity.to_f.should == @params[:quantity]
    end

    it 'should ignore non holding on record date' do
      Equity::Trader.handle_new_transaction(create(:equity_buy, @params.merge(date: @exdate - 1)))
      Equity::Trader.handle_new_transaction(create(:equity_sell, @params.merge(date: @exdate - 1)))
      FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2).apply
      transaction = EquityBuy.first
      transaction.price.to_f.should == @params[:price]
      transaction.quantity.to_f.should == @params[:quantity]
    end
  end
end