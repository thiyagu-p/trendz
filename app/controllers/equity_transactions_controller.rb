class EquityTransactionsController < ApplicationController
  def index
    @transactions = EquityTransaction.all
  end

  def new
    @equity_transaction = EquityTransaction.new
  end

  def create
    @equity_transaction = EquityTransaction.new(params[:equity_transaction])
    if @equity_transaction.save
      head :ok
    else
      @equity_transaction.errors.inspect
      render status: :unprocessable_entity, json: @equity_transaction.errors
    end
  end
end