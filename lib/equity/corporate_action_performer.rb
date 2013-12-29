module Equity

  class CorporateActionPerformer
    def self.perform
      actions_to_apply = "not applied and ex_date <= '#{Date.today}'"
      [FaceValueAction, BonusAction, DividendAction].each do |action_type|
        actions = action_type.send(:where, actions_to_apply).send(:to_a)
        actions.each { |action| action.apply }
      end
    end
  end
end