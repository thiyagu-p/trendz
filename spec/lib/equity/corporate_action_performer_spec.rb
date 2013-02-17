require 'spec_helper'

describe Equity::CorporateActionPerformer do

  before :each do
    @trading_account = TradingAccount.create
    @portfolio = Portfolio.create
    @stock = Stock.create
    @params = {quantity: 100, price: 250, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
    @exdate = Date.parse('1/1/2012')
  end

  describe 'bonus' do

    it 'should allocate bonus for specific stock' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 1, bonus_qty: 1))
      EquityTransaction.count.should == 2
    end

    it 'should allocate bonus for based on ratio of bonus and holding stock' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 2))
      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.quantity.should == 100 / 5 * 2
    end


    it 'should allocate bonus specific to trading account' do
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
      new_trading_account = TradingAccount.create
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 200, trading_account: new_trading_account))

      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))

      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, @trading_account.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_trading_account_id(@stock.id, @exdate, new_trading_account.id).quantity.should == 200 / 5 * 3
    end

    it 'should allocate bonus specific to portfolio' do
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 100))
      new_portfolio = Portfolio.create
      create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 200, portfolio: new_portfolio))

      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))

      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, @portfolio.id).quantity.should == 100 / 5 * 3
      EquityTransaction.find_by_stock_id_and_date_and_portfolio_id(@stock.id, @exdate, new_portfolio.id).quantity.should == 200 / 5 * 3
    end

    it 'should not allocate bonus for stocks purchased on ex-date' do
      create(:equity_buy, @params.merge(date: @exdate))

      expect {
        Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))
      }.to_not change { EquityTransaction.count }
    end

    it 'should not allocate bonus for stocks purchased after ex-date' do
      create(:equity_buy, @params.merge(date: @exdate + 1))

      expect {
        Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))
      }.to_not change { EquityTransaction.count }

    end

    it 'should not allocate bonus for non holding transaction on record date' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      create(:equity_sell, @params.merge(date: @exdate - 1))

      expect {
        Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))
      }.to_not change { EquityTransaction.count }

    end

    it 'should have 0 price and brokerage' do
      create(:equity_buy, @params.merge(date: @exdate - 1))

      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 5, bonus_qty: 3))

      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.price.should be_zero
      bonus_transaction.brokerage.should be_zero
    end

    it 'should have rounded quantity' do
      create(:equity_buy, @params.merge(date: @exdate - 1))

      Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 15, bonus_qty: 1))

      bonus_transaction = EquityTransaction.find_by_stock_id_and_date(@stock.id, @exdate)
      bonus_transaction.quantity.should == 6
    end

    it 'should not create bonus transaction if quantity is zero' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      expect { Equity::CorporateActionPerformer.apply(BonusAction.create!(stock: @stock, ex_date: @exdate, holding_qty: 200, bonus_qty: 3)) }.to_not change { EquityTransaction.count }
    end

  end

  describe 'split' do

    it 'should update quantity and price based on face value impact' do
      create(:equity_buy, @params.merge(date: @exdate - 1))
      Equity::CorporateActionPerformer.apply(action = FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2))
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

        expect{Equity::CorporateActionPerformer.apply(@action)}.to change{EquityTransaction.count}.by(1)
      end

      it 'should keep sold transaction with original price, sold quantity and proportionate brokerage' do
        Equity::CorporateActionPerformer.apply(@action)

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
        Equity::CorporateActionPerformer.apply(@action)

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

        Equity::CorporateActionPerformer.apply(@action)

        new_transaction = EquityBuy.where('id <> ?', @buy.id).first
        EquityTrade.find_by_equity_sell_id(@sell).equity_buy_id.should == @buy.id
        EquityTrade.find_by_equity_sell_id(@sell2).equity_buy_id.should == new_transaction.id
        EquityTrade.find_by_equity_sell_id(@sell3).equity_buy_id.should == new_transaction.id
      end
    end

    it 'should ignore future buy' do
      create(:equity_buy, @params.merge(date: @exdate))
      Equity::CorporateActionPerformer.apply(action = FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2))
      EquityTransaction.count.should == 1
      transaction = EquityTransaction.first
      transaction.price.to_f.should == @params[:price]
      transaction.quantity.to_f.should == @params[:quantity]
    end

    it 'should ignore non holding on record date' do
      Equity::Trader.handle_new_transaction(create(:equity_buy, @params.merge(date: @exdate - 1)))
      Equity::Trader.handle_new_transaction(create(:equity_sell, @params.merge(date: @exdate - 1)))
      Equity::CorporateActionPerformer.apply(action = FaceValueAction.create!(stock: @stock, ex_date: @exdate, from: 10, to: 2))
      transaction = EquityBuy.first
      transaction.price.to_f.should == @params[:price]
      transaction.quantity.to_f.should == @params[:quantity]
    end
  end
end



