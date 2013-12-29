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
      buy.apply_face_value_change(conversion_factor)
      buy.price.should == 120 * conversion_factor
      buy.quantity.should == 80 / conversion_factor
    end
  end

  describe ".partially_sold_on?" do
    before :each do
      @buy = create(:equity_buy, @hash.merge(quantity: 100, date: @date - 1))
      @sell_before = create(:equity_sell, @hash.merge(quantity: 20))
      @sell_after = create(:equity_sell, @hash.merge(quantity: 80, date: @date + 1))
      create(:equity_trade, equity_buy: @buy, equity_sell: @sell_before, quantity: @sell_before.quantity)
      create(:equity_trade, equity_buy: @buy, equity_sell: @sell_after, quantity: @sell_after.quantity)
    end
    context 'when partially sold' do
      it {expect(@buy.partially_sold_on?(@date)).to be true}
    end
    context 'when fully holding' do
      it {expect(@buy.partially_sold_on?(@date - 1)).to be false}
    end
    context 'when fully sold' do
      it {expect(@buy.partially_sold_on?(@date + 1)).to be false}
    end
  end

  describe ".holding_on?" do
    before :each do
      @buy = create(:equity_buy, @hash.merge(quantity: 100, date: @date - 1))
      @sell_before = create(:equity_sell, @hash.merge(quantity: 20))
      @sell_after = create(:equity_sell, @hash.merge(quantity: 80, date: @date + 1))
      create(:equity_trade, equity_buy: @buy, equity_sell: @sell_before, quantity: @sell_before.quantity)
      create(:equity_trade, equity_buy: @buy, equity_sell: @sell_after, quantity: @sell_after.quantity)
    end
    context 'when partially sold' do
      it {expect(@buy.holding_on?(@date)).to be true}
    end
    context 'when fully holding' do
      it {expect(@buy.holding_on?(@date - 1)).to be true}
    end
    context 'when fully sold' do
      it {expect(@buy.holding_on?(@date + 1)).to be false}
    end
    context 'when before purchase' do
      it {expect(@buy.holding_on?(@date - 5)).to be false}
    end
  end

  describe ".break_based_on_holding_on" do

    context "on break" do
      before :each do
        @buy = create(:equity_buy, @hash.merge(quantity: 100))
        @sell = create(:equity_sell, @hash.merge(quantity: 20))
        create(:equity_trade, equity_buy: @buy, equity_sell: @sell, quantity: @sell.quantity)
        @holding_qty = @buy.quantity - @sell.quantity
      end
      it "create a new transaction" do
        expect{@buy.break_based_on_holding_on(@date + 1)}.to change{EquityBuy.count}.by(1)
      end

      it "new transaction quantity should be holding quantity as on date" do
        new_transaction = @buy.break_based_on_holding_on(@date + 1)
        expect(new_transaction.quantity).to be(@holding_qty)
      end

      it "old transaction quantity should be sold quantity as on date" do
        @buy.break_based_on_holding_on(@date + 1)
        expect(@buy.quantity).to be(@sell.quantity)
      end

      it "brokerage should be split based on quantity" do
        brokerage_for_old = @buy.brokerage / @buy.quantity * (@buy.quantity - @holding_qty)
        brokerage_for_new = @buy.brokerage / @buy.quantity * @holding_qty
        new_transaction = @buy.break_based_on_holding_on(@date + 1)
        expect(new_transaction.brokerage).to be_within(0.01).of(brokerage_for_new)
        expect(@buy.brokerage).to be_within(0.01).of(brokerage_for_old)
      end

      it "except brokerage and quantity other attributes should remain same" do
        new_transaction = @buy.break_based_on_holding_on(@date + 1)
        ignored = ['id', 'brokerage', 'quantity', 'created_at', 'updated_at']
        expect(new_transaction.attributes.except(*ignored)).to eq(@buy.attributes.except(*ignored))
      end
    end

    context 'on mutiple sales' do
      before :each do
        @buy = create(:equity_buy, @hash.merge(quantity: 100))
        @sell_before = create(:equity_sell, @hash.merge(quantity: 5, date: @date - 1))
        @sell_on = create(:equity_sell, @hash.merge(quantity: 6))
        @sell_after = create(:equity_sell, @hash.merge(quantity: 21, date: @date + 1))
        create(:equity_trade, equity_buy: @buy, equity_sell: @sell_before, quantity: @sell_before.quantity)
        create(:equity_trade, equity_buy: @buy, equity_sell: @sell_on, quantity: @sell_on.quantity)
        create(:equity_trade, equity_buy: @buy, equity_sell: @sell_after, quantity: @sell_after.quantity)
      end

      it 'should consider sold on or before date as sold' do
        holding_qty = @buy.quantity - @sell_before.quantity - @sell_on.quantity
        new_transaction = @buy.break_based_on_holding_on(@date)
        expect(@buy.quantity).to be(@sell_before.quantity + @sell_on.quantity)
        expect(new_transaction.quantity).to be(holding_qty)
      end

      it 'should update trades past the date to point to new transaction' do
        new_transaction = @buy.break_based_on_holding_on(@date)
        expect(EquityTrade.find_by(equity_sell_id: @sell_after.id).equity_buy_id).to eq(new_transaction.id)
      end

      it 'should update trades past the date to point to new transaction' do
        new_transaction = @buy.break_based_on_holding_on(@date)
        expect(EquityTrade.find_by(equity_sell_id: @sell_on.id).equity_buy_id).to eq(@buy.id)
        expect(EquityTrade.find_by(equity_sell_id: @sell_before.id).equity_buy_id).to eq(@buy.id)
      end
    end

    context 'when no sale' do
      it 'should not create new transaction' do
        buy = create(:equity_buy)
        expect{buy.break_based_on_holding_on(@date)}.not_to change{EquityBuy.count}
      end
    end

    context 'when no holding' do
      it 'should not create new transaction' do
        buy = create(:equity_buy)
        sell = create(:equity_sell)
        create(:equity_trade, equity_buy: buy, equity_sell: sell, quantity: sell.quantity)
        expect{buy.break_based_on_holding_on(@date)}.not_to change{EquityBuy.count}
      end
    end

    it "should consider sales associated with the buy" do
      buy1 = create(:equity_buy, @hash)
      buy2 = create(:equity_buy, @hash)
      sell1 = create(:equity_sell, @hash.merge(quantity: 5))
      sell2 = create(:equity_sell, @hash.merge(quantity: 6))
      create(:equity_trade, equity_buy: buy1, equity_sell: sell1, quantity: sell1.quantity)
      create(:equity_trade, equity_buy: buy2, equity_sell: sell2, quantity: sell2.quantity)

      expect(buy1.break_based_on_holding_on(@date).quantity).to eq(@hash[:quantity] - sell1.quantity)
      expect(buy2.break_based_on_holding_on(@date).quantity).to eq(@hash[:quantity] - sell2.quantity)

    end
  end
end
