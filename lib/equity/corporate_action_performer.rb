module Equity
  class CorporateActionPerformer

    def self.apply action
      if action.instance_of? BonusAction
        TradingAccount.all.each do |trading_account|
          Portfolio.all.each do |portfolio|
            holding_qty = EquityTransaction.find_holding_quantity action.stock, action.ex_date - 1, trading_account, portfolio
            bonus_qty = holding_qty / action.holding_qty * action.bonus_qty
            EquityTransaction.create!(stock: action.stock, date: action.ex_date,
                                      trading_account: trading_account, portfolio: portfolio, quantity: bonus_qty,
                                      price: 0, brokerage: 0, action: EquityTransaction::BUY) if bonus_qty > 0
          end
        end
      end
    end

  end
end
