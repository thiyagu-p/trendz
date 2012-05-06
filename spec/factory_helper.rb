class FactoryHelper

  def self.create_equity_holding(params = {})
    quantity = params[:quantity] || 10
    transaction_params = params[:transaction]

    if quantity >= 0
      transaction_params = transaction_params.merge(quantity: quantity, action: EquityTransaction::BUY)
    else
      transaction_params = transaction_params.merge(quantity: -quantity, action: EquityTransaction::SELL)
    end

    FactoryGirl.create(:equity_holding, quantity: quantity, equity_transaction: FactoryGirl.create(:equity_transaction, transaction_params))
  end
end