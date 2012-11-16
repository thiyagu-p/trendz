module Equity
  class CorporateActionPerformer

    def self.apply corporate_action
      corporate_action.actions.each do |action|
        if action['type'] == 'bonus'
          TradingAccount.all.each do |trading_account|
            Portfolio.all.each do |portfolio|
              holding_qty = EquityTransaction.find_holding_quantity corporate_action.stock, corporate_action.ex_date - 1, trading_account, portfolio
              bonus_qty = holding_qty / action['holding'].to_i * action['bonus'].to_i
                EquityTransaction.create!(stock: corporate_action.stock, date: corporate_action.ex_date,
                                          trading_account: trading_account, portfolio: portfolio, quantity: bonus_qty,
                                          price: 0, brokerage: 0, action: EquityTransaction::BUY) if bonus_qty > 0
            end
          end
        end
      end
    end

  end
end
