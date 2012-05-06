require 'spec_helper'

describe EquityTransactionObserver do
  it 'on create of transaction should call trader' do
    Equity::Trader.expects(:handle_new_transaction)
    EquityTransaction.add_observer(EquityTransactionObserver.instance)
    create(:buy_equity_transaction)
  end
end
