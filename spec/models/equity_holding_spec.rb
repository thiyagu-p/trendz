require 'spec_helper'

describe EquityHolding do

  describe :tradeable_match do
    shared_examples_for "tradeable match filter" do |field|
      it "should find holding transactions belongs to same #{field}" do
        params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
        buy_transaction = create(:buy_equity_transaction, params)
        sell_transaction = create(:sell_equity_transaction, params)
        create(:equity_holding, equity_transaction: buy_transaction)
        create(:equity_holding, equity_transaction: create(:buy_equity_transaction, params.merge(field => create(field))))

        EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction]
      end
    end

    [:portfolio, :trading_account, :stock].each { |field| it_should_behave_like "tradeable match filter", field }


    it "should find all the holding quantities of the given match" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:buy_equity_transaction, params)
      buy_transaction2 = create(:buy_equity_transaction, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      sell_transaction = create(:sell_equity_transaction, params)

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction1, buy_transaction2]
    end

    it "should find transactions with opposite action" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:buy_equity_transaction, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      sell_transaction1 = create(:sell_equity_transaction, params)
      EquityHolding.tradeable_match(sell_transaction1).collect(&:equity_transaction).should == [buy_transaction1]

      buy_transaction2 = create(:buy_equity_transaction, params)
      sell_transaction2 = create(:sell_equity_transaction, params)
      create(:equity_holding, equity_transaction: sell_transaction2)
      EquityHolding.tradeable_match(buy_transaction2).collect(&:equity_transaction).should == [sell_transaction2]
    end

    it "should find matching delivery based" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock), delivery: false}
      buy_transaction1 = create(:buy_equity_transaction, params)
      create(:equity_holding, equity_transaction: buy_transaction1)
      sell_transaction1 = create(:sell_equity_transaction, params)

      buy_transaction2 = create(:buy_equity_transaction, params.merge(delivery: true))
      create(:equity_holding, equity_transaction: buy_transaction2)

      EquityHolding.tradeable_match(sell_transaction1).collect(&:equity_transaction).should == [buy_transaction1]
    end

    it "should find all the holding quantities ordered by earliest first" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:buy_equity_transaction, params.merge(date: Date.parse('2/1/2012')))
      buy_transaction2 = create(:buy_equity_transaction, params.merge(date: Date.parse('1/1/2012')))
      buy_transaction3 = create(:buy_equity_transaction, params.merge(date: Date.parse('3/1/2012')))
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      create(:equity_holding, equity_transaction: buy_transaction3)
      sell_transaction = create(:sell_equity_transaction, params)

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction2, buy_transaction1, buy_transaction3]
    end

    it "should find transactions done on or before of given transaction" do
      params = {portfolio: create(:portfolio), trading_account: create(:trading_account), stock: create(:stock)}
      buy_transaction1 = create(:buy_equity_transaction, params.merge(date: Date.parse('2/1/2012')))
      buy_transaction2 = create(:buy_equity_transaction, params.merge(date: Date.parse('1/1/2012')))
      buy_transaction3 = create(:buy_equity_transaction, params.merge(date: Date.parse('3/1/2012')))
      create(:equity_holding, equity_transaction: buy_transaction1)
      create(:equity_holding, equity_transaction: buy_transaction2)
      create(:equity_holding, equity_transaction: buy_transaction3)
      sell_transaction = create(:sell_equity_transaction, params.merge(date: Date.parse('2/1/2012')))

      EquityHolding.tradeable_match(sell_transaction).collect(&:equity_transaction).should == [buy_transaction2, buy_transaction1]
    end
  end
end