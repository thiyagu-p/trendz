require 'spec_helper'

describe EquityHolding do

  describe :tradeable_match do
    shared_examples_for "tradeable match filter" do |field|
      it "should find holding transactions belongs to same #{field}" do
        params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
        buy_transaction = create(:equity_buy, params)
        sell_transaction = create(:equity_sell, params)
        create(:equity_holding, equity_transaction: buy_transaction)
        create(:equity_holding, equity_transaction: create(:equity_buy, params.merge(field => create(field))))

        EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction]
      end
    end

    [:portfolio, :trading_account, :stock].each { |field| it_should_behave_like "tradeable match filter", field }


    it "should find all the holding quantities of the given match" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:equity_buy, params)
      buy_transaction2 = create(:equity_buy, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      sell_transaction = create(:equity_sell, params)

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction1, buy_transaction2]
    end

    it "should find transactions with opposite action" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:equity_buy, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      sell_transaction1 = create(:equity_sell, params)
      EquityHolding.tradeable_match(sell_transaction1).collect(&:equity_transaction).should == [buy_transaction1]

      buy_transaction2 = create(:equity_buy, params)
      sell_transaction2 = create(:equity_sell, params)
      create(:equity_holding, equity_transaction: sell_transaction2)
      EquityHolding.tradeable_match(buy_transaction2).collect(&:equity_transaction).should == [sell_transaction2]
    end

    it "should find matching delivery based" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock), delivery: false}
      buy_transaction1 = create(:equity_buy, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      sell_transaction1 = create(:equity_sell, params)

      buy_transaction2 = create(:equity_buy, params.merge(delivery: true))
      create(:equity_holding, equity_transaction: buy_transaction2)

      EquityHolding.tradeable_match(sell_transaction1).collect(&:equity_transaction).should == [buy_transaction1]
    end

    it "should find all the holding quantities ordered by earliest first" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:equity_buy, params.merge(date: Date.parse('2/1/2012')))
      buy_transaction2 = create(:equity_buy, params.merge(date: Date.parse('1/1/2012')))
      buy_transaction3 = create(:equity_buy, params.merge(date: Date.parse('3/1/2012')))
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      create(:equity_holding, equity_transaction: buy_transaction3)
      sell_transaction = create(:equity_sell, params)

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction2, buy_transaction1, buy_transaction3]
    end

    it "should find transactions done on or before for sell transaction" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:equity_buy, params.merge(date: Date.parse('2/1/2012')))
      buy_transaction2 = create(:equity_buy, params.merge(date: Date.parse('1/1/2012')))
      buy_transaction3 = create(:equity_buy, params.merge(date: Date.parse('3/1/2012')))
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      create(:equity_holding, equity_transaction: buy_transaction3)
      sell_transaction = create(:equity_sell, params.merge(date: Date.parse('2/1/2012')))

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction2, buy_transaction1]
    end

    it "should find transactions done on same day for buy transaction" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      sell_transaction1 = create(:equity_sell, params.merge(date: Date.parse('2/1/2012')))
      sell_transaction2 = create(:equity_sell, params.merge(date: Date.parse('1/1/2012')))
      sell_transaction3 = create(:equity_sell, params.merge(date: Date.parse('3/1/2012')))
      create(:equity_holding, equity_transaction: sell_transaction1)
      create(:equity_holding, equity_transaction: sell_transaction2)
      create(:equity_holding, equity_transaction: sell_transaction3)
      buy_transaction = create(:equity_buy, params.merge(date: Date.parse('2/1/2012')))

      EquityHolding.tradeable_match(buy_transaction).collect(&:equity_transaction).should == [sell_transaction1]
    end
  end

  describe :consolidated do

    it 'should sum quantities belong to same symbol, portfolio and trading account' do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:equity_buy, params.merge(date: Date.parse('2/1/2012')))
      buy_transaction2 = create(:equity_buy, params.merge(date: Date.parse('1/1/2012')))
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)

      consolidated_list = EquityHolding.consolidated
      consolidated_list.all.size.should == 1
      consolidated_list.first.quantity = buy_transaction1.quantity + buy_transaction2.quantity
      consolidated_list.first.portfolio_id = params[:portfolio].id
      consolidated_list.first.trading_account_id = params[:trading_account].id
      consolidated_list.first.stock_id = params[:stock].id
    end

    it 'should order by portfolio, symbol, quantity and trading account' do
      EquityHolding.consolidated.order_values.should == [:portfolio_id, :stock_id, :quantity, :trading_account_id]
    end

    shared_examples_for "consolidation group" do |field|
      it "should not group different #{field} together" do
        params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
        create(:equity_holding, equity_transaction: (buy_transaction1 = create(:equity_buy, params)))
        create(:equity_holding, equity_transaction: (buy_transaction2 = create(:equity_buy, params)))
        create(:equity_holding, equity_transaction: (buy_transaction3 = create(:equity_buy, params.merge(field => create(field)))))

        consolidated_list = EquityHolding.consolidated
        list_of_ids = consolidated_list.collect {|holding| holding.send("#{field}_id").to_i}
        list_of_ids.should =~ [buy_transaction1.send("#{field}_id"), buy_transaction3.send("#{field}_id")]
      end
    end

    [:portfolio, :trading_account, :stock].each { |field| it_should_behave_like "consolidation group", field }

  end
end