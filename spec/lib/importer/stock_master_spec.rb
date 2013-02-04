require 'spec_helper'

describe Importer::StockMaster do

  it "should import" do
    Importer::StockMaster.new.import
    Stock.count.should > 0
    ongc = Stock.find_by_symbol 'ONGC'
    ongc.name.should == 'Oil & Natural Gas Corporation Limited'
    ongc.face_value.should == 5
    ongc.isin.should == 'INE213A01029'
  end
end


