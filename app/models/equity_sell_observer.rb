class EquitySellObserver < ActiveRecord::Observer

  def after_create(transaction)
    Equity::Trader.handle_new_transaction(transaction)
  end


end
