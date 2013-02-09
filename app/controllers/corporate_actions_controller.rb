class CorporateActionsController < ApplicationController

  before_filter :load_stock_list

  def index

  end

  def show
    @stock = Stock.find_by_symbol(params[:id])
    @dividend_actions = DividendAction.where("stock_id = ?", @stock.id).order('ex_date desc')
    @bonus_actions = BonusAction.where("stock_id = ?", @stock.id).order('ex_date desc')
    @face_value_actions = FaceValueAction.where("stock_id = ?", @stock.id).order('ex_date desc')
    @action_errors = CorporateActionError.where("stock_id = ?", @stock.id).order('ex_date desc')
  end

  private
  def load_stock_list
    @stocks = Stock.order(:symbol)
  end

end
