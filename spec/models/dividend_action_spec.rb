require 'spec_helper'

describe DividendAction do
  before :each do
    @stock = create(:stock, face_value: 5)
  end

  describe 'future_actions_with_current_percentage' do
    it "should find future actions" do
      EqQuote.create!(stock: @stock, close: 100, date: Date.yesterday)
      dividend = DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.size.should == 1
      dividends.first.should == dividend
    end

    it "should find current_percentage" do
      EqQuote.create!(stock: @stock, close: 100, date: Date.yesterday)
      DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.first.current_percentage == 1.20
    end
    it "should ignore actions which doesn't have latest quote" do
      DividendAction.create!(stock: @stock, percentage: 25, ex_date: Date.today)
      dividends = DividendAction.future_dividends_with_current_percentage
      dividends.empty?.should be_true
    end
  end

  describe '.value' do
    it 'calculated as face value percentage' do
      action = DividendAction.create!(stock: create(:stock, face_value: 5), percentage: 25, ex_date: @exdate)
      expect(action.value).to be_within(0.01).of(25.0 / 100.0 * 5.0)

      action = DividendAction.create!(stock: create(:stock, face_value: 20), percentage: 10, ex_date: @exdate)
      expect(action.value).to be_within(0.01).of(10.0 / 100.0 * 20.0)
    end
  end

  describe 'apply' do
    before :each do
      @trading_account = TradingAccount.create
      @portfolio = Portfolio.create
      @exdate = Date.parse('1/1/2012')
      @params = {quantity: 100, price: 250, brokerage: 200, portfolio: @portfolio, trading_account: @trading_account, stock: @stock, delivery: true}
      @action = DividendAction.create!(stock: @stock, percentage: 25, ex_date: @exdate)
      @buy = create(:equity_buy, @params.merge(date: @exdate - 1))
    end

    context 'holding stock' do
      it 'accumulate dividend' do
        expect{@action.apply}.to change{DividendTransaction.count}.by(1)
      end

      it 'dividend value based on quantity' do
        @action.apply
        expect(DividendTransaction.first.value).to eq(@action.value * @buy.quantity)
      end

      it 'no double dividend' do
        expect{@action.apply}.to change{DividendTransaction.count}.by(1)
        expect{@action.apply}.not_to change{DividendTransaction.count}
      end

      it 'separate dividend for each transaction' do
        buy2 = create(:equity_buy, @params.merge(date: @exdate - 1, quantity: 5))
        @action.apply
        expect(DividendTransaction.find_by(equity_transaction_id: @buy.id).value).to eq(@action.value * @buy.quantity)
        expect(DividendTransaction.find_by(equity_transaction_id: buy2.id).value).to eq(@action.value * buy2.quantity)
      end

    end

    context 'partial holding' do
      it 'accumulate dividend only for holding qty' do
        sell = create(:equity_sell, @params.merge(date: @exdate - 1, quantity: 5))
        create(:equity_trade, equity_buy: @buy, equity_sell: sell, quantity: sell.quantity)

        @action.apply
        expect(DividendTransaction.find_by(equity_transaction_id: @buy.id).value).to eq(@action.value * @buy.holding_qty_on(@exdate - 1))
      end
    end

    context 'no holding' do
      it 'no dividend before purchase' do
        buy_later = create(:equity_buy, @params.merge(date: @exdate, quantity: 5))

        @action.apply
        expect(DividendTransaction.find_by(equity_transaction_id: buy_later.id)).to be_nil
      end
      it 'no dividend after sales' do
        buy = create(:equity_buy, @params.merge(date: @exdate - 10))
        sell = create(:equity_sell, @params.merge(date: @exdate - 5))
        create(:equity_trade, equity_buy: buy, equity_sell: sell, quantity: sell.quantity)

        @action.apply
        expect(DividendTransaction.find_by(equity_transaction_id: buy.id)).to be_nil
      end
      it 'no dividend if sold on record date' do
        buy = create(:equity_buy, @params.merge(date: @exdate - 1))
        sell = create(:equity_sell, @params.merge(date: @exdate - 1))
        create(:equity_trade, equity_buy: buy, equity_sell: sell, quantity: sell.quantity)

        @action.apply
        expect(DividendTransaction.find_by(equity_transaction_id: buy.id)).to be_nil
      end
    end

    it 'should mark as applied' do
      @action.apply
      expect(@action.applied?).to be true
    end


  end
end