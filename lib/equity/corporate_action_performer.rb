class CorporateActionPerformer

  def self.perform
    actions_to_apply = "not applied and ex_date <= '#{Date.today}'"
    [BonusAction, FaceValueAction].each do |action_type|
      actions = action_type.send(:where, actions_to_apply).send(:to_a)
      actions.each {|action| action.apply}
    end
    #DividendAction.all(conditions: actions_to_apply).each {|dividend| dividend.apply}
  end
end