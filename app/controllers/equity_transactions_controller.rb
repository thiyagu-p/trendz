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
    @equity_transaction = action == EquityTransaction::BUY ? EquityBuy.new(equity_params) : EquitySell.new(equity_params)
    if @equity_transaction.save
      Equity::Trader.handle_new_transaction(@equity_transaction)
      head :ok
    else
      @equity_transaction.errors.inspect
      render status: :unprocessable_entity, json: @equity_transaction.errors
    end
  end

  private
  def equity_params
    params.require(:equity_transaction).permit(:quantity, :date, :price, :brokerage, :trading_account_id, :portfolio_id, :stock_id, :delivery)
  end

end