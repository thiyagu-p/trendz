module Equity

  class CorporateActionHandler
    def self.apply_all
      actions_to_apply = "not applied and ex_date <= '#{Date.today}'"
      [FaceValueAction, BonusAction, DividendAction].each do |action_type|
        actions = action_type.send(:where, actions_to_apply).send(:to_a)
        actions.each { |action| action.apply }
      end
    end

    def self.apply_pending_upto(stock, date)
      actions_to_apply = "stock_id = #{stock.id} and ex_date <= '#{date}'"
      [FaceValueAction, BonusAction, DividendAction].each do |action_type|
        actions = action_type.send(:where, actions_to_apply).send(:to_a)
        actions.each { |action| action.apply_on_portfolio }
      end
    end
  end
end