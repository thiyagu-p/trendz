module Equity
  class Trader

    def self.handle_new_transaction(new_transaction)
      EquityTransaction.transaction do
        holdings = EquityHolding.tradeable_match(new_transaction)
        if new_transaction.instance_of? EquityBuy
          handle_buy(holdings, new_transaction)
        else
          handle_sell(holdings, new_transaction)
        end
      end
    end

    private

    def self.handle_sell(holdings, new_transaction)
      quantity_to_match = new_transaction.quantity
      while quantity_to_match > 0 && holdings.any?
        holding = holdings.shift
        buy, sell = [holding.equity_transaction, new_transaction]
        if holding.quantity == quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: quantity_to_match)
          holding.destroy
          quantity_to_match = 0
        elsif holding.quantity > quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: quantity_to_match)
          holding.update_attributes!(quantity: (holding.quantity - quantity_to_match))
          quantity_to_match = 0
        elsif holding.quantity < quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: holding.quantity)
          quantity_to_match -= holding.quantity
          holding.destroy
        end
      end
      if quantity_to_match != 0
        EquityHolding.create(equity_transaction: new_transaction, quantity: -quantity_to_match)
      end
    end

    def self.handle_buy(holdings, new_transaction)
      quantity_to_match = new_transaction.quantity
      while quantity_to_match > 0 && holdings.any?
        holding = holdings.shift
        buy, sell = [new_transaction, holding.equity_transaction]
        if -holding.quantity == quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: quantity_to_match)
          holding.destroy
          quantity_to_match = 0
        elsif (-holding.quantity) > quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: quantity_to_match)
          holding.update_attributes!(quantity: holding.quantity + quantity_to_match)
          quantity_to_match = 0
        elsif (-holding.quantity) < quantity_to_match
          EquityTrade.create(equity_buy: buy, equity_sell: sell, quantity: -holding.quantity)
          quantity_to_match += holding.quantity
          holding.destroy
        end
      end

      if quantity_to_match != 0
        EquityHolding.create(equity_transaction: new_transaction, quantity: quantity_to_match)
      end
    end
  end
end
