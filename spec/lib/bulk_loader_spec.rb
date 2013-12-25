require "spec_helper"

describe BulkLoader do

  it "should handle buy split sell scenario" do
    stock = create :stock, symbol: 'BHARTIARTL'
    date = Date.parse('20090724')
    FaceValueAction.create! stock: stock, ex_date: date, from: 10, to:5
    bulk_loader = BulkLoader.new
    bulk_loader.send(:handle_transaction, '20080429,BHARTIARTL,Buy,5.0,904.95,34.70,Sugi,Hdfc', {})
    bulk_loader.send(:handle_transaction, '20101119,BHARTIARTL,Sell,10.0,333.8,32.03,Sugi,Hdfc', {})
    EquityBuy.first.quantity.should == 10
    EquityHolding.count.should == 0
  end
end