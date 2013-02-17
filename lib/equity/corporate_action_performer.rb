module Equity
  class CorporateActionPerformer

    def self.apply action
      if action.instance_of? BonusAction
        TradingAccount.all.each do |trading_account|
          Portfolio.all.each do |portfolio|
            holding_qty = EquityBuy.find_holding_quantity action.stock, action.ex_date - 1, trading_account, portfolio
            bonus_qty = holding_qty / action.holding_qty * action.bonus_qty
            EquityBuy.create!(stock: action.stock, date: action.ex_date,
                                      trading_account: trading_account, portfolio: portfolio, quantity: bonus_qty,
                                      price: 0, brokerage: 0) if bonus_qty > 0
          end
        end
      elsif action.instance_of? FaceValueAction
        TradingAccount.all.each do |trading_account|
          Portfolio.all.each do |portfolio|
            holdings = EquityBuy.find_holdings_on action.stock, action.ex_date - 1, trading_account, portfolio
            holdings.each do |transaction|
              transaction.apply_face_value_change(action.conversion_ration, action.ex_date - 1)
            end
          end
        end
      end
    end
  end
end
