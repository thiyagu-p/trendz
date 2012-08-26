class HomeController < ApplicationController

  def index
    @corporate_actions = CorporateAction.future_actions_with_current_percentage
    @equity_holding = EquityHolding.all
  end
end
