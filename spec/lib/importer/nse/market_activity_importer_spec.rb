require 'spec_helper'
require 'zip/zipfilesystem'

describe Importer::Nse::MarketActivityImporter do

  describe 'FT', ft: true do

    before :each do
      @importer = Importer::Nse::MarketActivityImporter.new
      MarketActivity.expects(:maximum).returns(Date.parse('8/9/2011'))
      MarketActivity.expects(:maximum).with('date', {:conditions => 'fii_index_futures_buy is not null'}).returns(Date.parse('9/9/2011'))
      Date.stubs(:today).returns(Date.parse('9/9/2011'))
      @importer.import
      @market_activity = MarketActivity.find_by_date('9/9/2011')
    end

    it "should import equity data, index f&o and stock f&o", ft: true do
      @market_activity.fii_buy_equity.should == 2355.77
      @market_activity.fii_sell_equity.should == 2783.44
      @market_activity.dii_buy_equity.should == 1125.20
      @market_activity.dii_sell_equity.should == 1040.13

      @market_activity.fii_index_futures_buy.to_f.should == 1963.32
      @market_activity.fii_index_futures_sell.to_f.should == 2679.21
      @market_activity.fii_index_futures_oi.to_f.should == 686832
      @market_activity.fii_index_futures_oi_value.to_f.should == 17271.39

      @market_activity.fii_index_options_buy.to_f.should == 11454.09
      @market_activity.fii_index_options_sell.to_f.should == 10763.66
      @market_activity.fii_index_options_oi.to_f.should == 2199577
      @market_activity.fii_index_options_oi_value.to_f.should == 55635.28

      @market_activity.fii_stock_futures_buy.to_f.should == 1862.46
      @market_activity.fii_stock_futures_sell.to_f.should == 1716.04
      @market_activity.fii_stock_futures_oi.to_f.should == 1161573
      @market_activity.fii_stock_futures_oi_value.to_f.should == 28926.35

      @market_activity.fii_stock_options_buy.to_f.should == 406.81
      @market_activity.fii_stock_options_sell.to_f.should == 385.40
      @market_activity.fii_stock_options_oi.to_f.should == 47980
      @market_activity.fii_stock_options_oi_value.to_f.should == 1158.08
    end
  end

  describe 'UT' do
    it 'should skip missing file' do
      @importer = Importer::Nse::MarketActivityImporter.new
      date = Date.parse('9/9/2011')
      MarketActivity.expects(:maximum).returns(date)
      MarketActivity.create(date: date)
      Date.stubs(:today).returns(date)
      @importer.expects(:get).returns(stub(:class => Net::HTTPNotFound))

      lambda {@importer.import_fo_data}.should_not raise_error
    end
  end
end