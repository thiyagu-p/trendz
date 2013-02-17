class EquityTransactionsController < ApplicationController
  def index
    @transactions = EquityTransaction.includes([:stock, :portfolio, :trading_account]).all
    @consolidated_holdings = EquityHolding.delivery.consolidated
  end

  def new
    @equity_transaction = EquityTransaction.new
  end

  def create
    action = params[:equity_transaction].delete 'type'
    @equity_transaction = action == EquityTransaction::BUY ? EquityBuy.new(params[:equity_transaction]) : EquitySell.new(params[:equity_transaction])
    if @equity_transaction.save
      head :ok
    else
      @equity_transaction.errors.inspect
      render status: :unprocessable_entity, json: @equity_transaction.errors
    end
  end
end