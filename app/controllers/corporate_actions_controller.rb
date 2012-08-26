class CorporateActionsController < ApplicationController

  before_filter :load_stock_list

  def index

  end

  def show
    @stock = Stock.find_by_symbol(params[:id])
    @corporate_actions = CorporateAction.order('ex_date desc').find_all_by_stock_id(@stock.id)
  end

  private
  def load_stock_list
    @stocks = Stock.order(:symbol)
  end

end
