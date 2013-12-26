require 'spec_helper'
require 'zip/zipfilesystem'

describe Importer::Nse::EquityBhav do

  describe 'processing dates' do
    before(:each) do
      @http = stub()
      ImportStatus.find_or_create_by(source: ImportStatus::Source::NSE_EQUITIES_BHAV)
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @importer = Importer::Nse::EquityBhav.new
    end

    it "should import start from next day of last available date upto current date" do
      EqQuote.expects(:maximum).returns(Date.parse('1/2/2010'))
      Date.stubs(:today).returns(Date.parse('4/2/2010'))
      @http.expects(:request_get).with('/content/historical/EQUITIES/2010/FEB/cm02FEB2010bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      @http.expects(:request_get).with('/content/historical/EQUITIES/2010/FEB/cm03FEB2010bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      @http.expects(:request_get).with('/content/historical/EQUITIES/2010/FEB/cm04FEB2010bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      @importer.import
    end

    it "should import start from specified date if no prior equity quote" do
      EqQuote.expects(:maximum).returns(nil)
      Date.stubs(:today).returns(Date.parse('2/1/2011'))
      @http.expects(:request_get).with('/content/historical/EQUITIES/2011/JAN/cm01JAN2011bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      @http.expects(:request_get).with('/content/historical/EQUITIES/2011/JAN/cm02JAN2011bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      @importer.import
    end
  end

  describe 'processing bhav file content' do

    before(:each) do
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      ImportStatus.find_or_create_by(source: ImportStatus::Source::NSE_EQUITIES_BHAV)
      @importer = Importer::Nse::EquityBhav.new
      EqQuote.expects(:maximum).returns(Date.parse('23/6/2011'))
      Date.stubs(:today).returns(Date.parse('24/6/2011'))
      response = stub(:body => File.open('spec/sample/cm24JUN2011bhav.csv.zip').read )
      @http.expects(:request_get).with('/content/historical/EQUITIES/2011/JUN/cm24JUN2011bhav.csv.zip', Importer::Nse::Connection.user_agent).returns(response)
      @importer.import
    end

    it "should import end of day data from zip file" do
      stock = Stock.find_by(symbol: '20MICRONS')
      quote = EqQuote.find_by(stock_id: stock.id)
      quote.open.should == 46
      quote.high.should == 47.8
      quote.low.should == 45.6
      quote.close.should == 46.5
      quote.previous_close.should == 46.05
      quote.traded_quantity.should == 10706
    end

    it "should import all valid quotes" do
      EqQuote.count.should == 3
    end

    it "should update 10, 50, 200 days moving average" do
      stock = Stock.find_by(symbol: '20MICRONS')
      quote = EqQuote.find_by(stock_id: stock.id)
      quote.mov_avg_10d.should_not eq(0)
      quote.mov_avg_50d.should_not eq(0)
      quote.mov_avg_200d.should_not eq(0)
    end

    it "should handle new stock codes" do
      Stock.count.should == 3
      Stock.find_by(symbol: '20MICRONS').nse_series.should == Stock::NseSeries::EQUITY
    end

  end
end