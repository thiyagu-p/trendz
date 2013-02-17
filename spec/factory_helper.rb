class FactoryHelper

  def self.create_equity_holding(params = {})
    quantity = params[:quantity] || 10
    transaction_params = params[:transaction]

    transaction = quantity >= 0 ? FactoryGirl.create(:equity_buy, transaction_params.merge(quantity: quantity)) :
        FactoryGirl.create(:equity_sell, transaction_params.merge(quantity: -quantity))

    FactoryGirl.create(:equity_holding, quantity: quantity, equity_transaction: transaction)
  end
end