class HomeController < ApplicationController

  def index
    @dividend_actions = DividendAction.future_dividends_with_current_percentage
    @bonus_actions = BonusAction.where("ex_date >= ?" , Date.today).order(:ex_date)
    @face_value_actions = FaceValueAction.where("ex_date >= ?" , Date.today).order(:ex_date)
    @action_errors = CorporateActionError.where("ex_date >= ? and not is_ignored" , Date.today).order(:ex_date)
    @equity_holding = EquityHolding.all
    @year_beginning = EqQuote.where("date >= ?", Date.today.beginning_of_year).minimum(:date)
  end
end
