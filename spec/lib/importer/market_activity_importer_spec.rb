require 'spec_helper'
require 'zip/zipfilesystem'

describe Importer::MarketActivityImporter do

  describe 'FT' do

    before :all do
      @importer = Importer::MarketActivityImporter.new
      MarketActivity.expects(:maximum).returns(Date.parse('30/1/2012'))
      Date.stubs(:today).returns(Date.parse('31/1/2012'))
      @importer.import
      @market_activity = MarketActivity.find_by_date('1/31/2012')
    end

    it "should import equity data" do
      @market_activity.fii_buy_equity.to_f.should == 2577.60
      @market_activity.fii_sell_equity.to_f.should == 2657.20
      @market_activity.fii_buy_debit.to_f.should == 315.7
      @market_activity.fii_sell_debit.to_f.should == 786.50
    end

    it "should import index f&o" do
      @market_activity.fii_index_futures_buy.to_f.should == 1077.31
      @market_activity.fii_index_futures_sell.to_f.should == 2232.25
      @market_activity.fii_index_futures_oi.to_f.should == 446521
      @market_activity.fii_index_futures_oi_value.to_f.should == 11322.06

      @market_activity.fii_index_options_buy.to_f.should == 8573.54
      @market_activity.fii_index_options_sell.to_f.should == 7677.47
      @market_activity.fii_index_options_oi.to_f.should == 1180262
      @market_activity.fii_index_options_oi_value.to_f.should == 30001.66
    end

    it "should import stock f&o" do
      @market_activity.fii_stock_futures_buy.to_f.should == 1482.93
      @market_activity.fii_stock_futures_sell.to_f.should == 1642.68
      @market_activity.fii_stock_futures_oi.to_f.should == 963306
      @market_activity.fii_stock_futures_oi_value.to_f.should == 25751.51

      @market_activity.fii_stock_options_buy.to_f.should == 579.79
      @market_activity.fii_stock_options_sell.to_f.should == 583.99
      @market_activity.fii_stock_options_oi.to_f.should == 30471
      @market_activity.fii_stock_options_oi_value.to_f.should == 809.74
    end
  end

  describe 'UT' do
     it "should import for each month starting from last available date upto current date" do
       @importer = Importer::MarketActivityImporter.new
       MarketActivity.expects(:maximum).returns(Date.parse('30/10/2011'))
       Date.stubs(:today).returns(Date.parse('21/1/2012'))
       Net::HTTP.expects(:post_form).with(Importer::MarketActivityImporter::SEBI_URL, {txtCalendar: '31/10/2011'}).returns(['', ''])
       Net::HTTP.expects(:post_form).with(Importer::MarketActivityImporter::SEBI_URL, {txtCalendar: '30/11/2011'}).returns(['', ''])
       Net::HTTP.expects(:post_form).with(Importer::MarketActivityImporter::SEBI_URL, {txtCalendar: '31/12/2011'}).returns(['', ''])
       Net::HTTP.expects(:post_form).with(Importer::MarketActivityImporter::SEBI_URL, {txtCalendar: '21/01/2012'}).returns(['', ''])
       @importer.import
     end
  end
end