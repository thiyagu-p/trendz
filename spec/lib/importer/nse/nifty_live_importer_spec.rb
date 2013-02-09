require "spec_helper"

describe Importer::Nse::NiftyLiveImporter do
  describe 'UT' do
    before :each do
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @stock = Stock.create!(symbol: 'NIFTY')
    end

    describe 'Import Skip' do

      it "should not import if bhav is not imported yet for the day" do
        json_data = '{"data":[{"timeVal":"Sep 14, 2011 16:01:17","indexName":"S&P CNX NIFTY","previousClose":"5,012.55","open":"5,062.35","high":"5,091.45","low":"4,967.45","last":"5,075.70","percChange":"1.26","indexOrder":"0.00"}]}'
        @http.expects(:request_get).with('/live_market/dynaContent/live_watch/stock_watch/liveIndexWatchData.json', Importer::Nse::Connection.user_agent).returns(stub(:body => json_data))
        @date = Date.parse('14/09/2011')
        Importer::Nse::NiftyLiveImporter.new.import
        EqQuote.find_by_stock_id_and_date(@stock.id, @date).should be_nil
      end

    end

    describe 'Import Success' do

      before :each do
        @http.expects(:request_get).with('/live_market/dynaContent/live_watch/stock_watch/liveIndexWatchData.json', Importer::Nse::Connection.user_agent).returns(stub(:body => json_data))
        @date = Date.parse('15/09/2011')
        set_bhav_imported @date
      end

      it "should import" do
        Importer::Nse::NiftyLiveImporter.new.import
        quote = EqQuote.find_by_stock_id_and_date(@stock.id, @date)
        quote.open.should == 5062.35
        quote.high.should == 5091.45
        quote.low.should == 4967.45
        quote.close.should == 5075.70
        quote.mov_avg_10d.should_not eq(0)
        quote.mov_avg_50d.should_not eq(0)
        quote.mov_avg_200d.should_not eq(0)
      end

      it "should update if quote already present" do
        EqQuote.create(stock: @stock, date: @date)

        Importer::Nse::NiftyLiveImporter.new.import
        quotes = EqQuote.find_all_by_stock_id_and_date(@stock.id, @date)
        quotes.size.should == 1
        quotes.first.close.to_f.should == 5075.70
      end
    end
  end

  describe 'FT' do
    it "should import" do
      EqQuote.stubs(:find_by_date).returns(EqQuote.new)
      stock = Stock.create(symbol: 'NIFTY')
      Importer::Nse::NiftyLiveImporter.new.import
      quotes = EqQuote.find_all_by_stock_id(stock.id)
      quotes.size.should == 1
      quotes.first.close.should_not eq(0)
    end
  end
end

def json_data
  <<EOF
{"data":[{"timeVal":"Sep 15, 2011 16:01:17","indexName":"S&P CNX NIFTY","previousClose":"5,012.55","open":"5,062.35","high":"5,091.45","low":"4,967.45","last":"5,075.70","percChange":"1.26","indexOrder":"0.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX NIFTY JUNIOR","previousClose":"9,995.00","open":"10,002.90","high":"10,162.40","low":"10,002.90","last":"10,147.65","percChange":"1.53","indexOrder":"1.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX IT","previousClose":"5,425.10","open":"5,484.85","high":"5,570.60","low":"5,385.95","last":"5,550.15","percChange":"2.31","indexOrder":"2.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"BANK NIFTY","previousClose":"9,472.45","open":"9,569.35","high":"9,708.80","low":"9,390.10","last":"9,660.35","percChange":"1.98","indexOrder":"3.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"INDIA VIX","previousClose":"32.45","open":"32.45","high":"33.72","low":"29.91","last":"30.79","percChange":"-5.12","indexOrder":"4.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX 100","previousClose":"4,931.10","open":"4,972.60","high":"5,009.05","low":"4,897.55","last":"4,995.40","percChange":"1.30","indexOrder":"5.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"S&P CNX DEFTY","previousClose":"3,635.25","open":"3,674.65","high":"3,711.75","low":"3,593.55","last":"3,692.55","percChange":"1.58","indexOrder":"6.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"S&P CNX 500","previousClose":"4,051.55","open":"4,078.90","high":"4,105.85","low":"4,029.10","last":"4,097.00","percChange":"1.12","indexOrder":"7.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX MIDCAP","previousClose":"7,262.75","open":"7,264.00","high":"7,345.40","low":"7,264.00","last":"7,340.40","percChange":"1.07","indexOrder":"8.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"NIFTY MIDCAP 50","previousClose":"2,167.45","open":"2,173.90","high":"2,199.65","low":"2,171.25","last":"2,197.85","percChange":"1.40","indexOrder":"10.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX INFRA","previousClose":"2,726.60","open":"2,747.20","high":"2,748.65","low":"2,701.30","last":"2,739.10","percChange":"0.46","indexOrder":"11.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX REALTY","previousClose":"231.30","open":"231.35","high":"240.70","low":"231.35","last":"239.70","percChange":"3.63","indexOrder":"12.00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX SERVICE","previousClose":"5,895.70","open":"5,957.70","high":"6,035.35","low":"5,848.35","last":"6,009.30","percChange":"1.93","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX ENERGY","previousClose":"7,788.95","open":"7,857.50","high":"7,892.60","low":"7,719.90","last":"7,879.20","percChange":"1.16","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX FMCG","previousClose":"10,178.85","open":"10,256.85","high":"10,256.85","low":"10,051.65","last":"10,152.20","percChange":"-0.26","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX PSU BANK","previousClose":"3,129.15","open":"3,147.60","high":"3,226.30","low":"3,136.45","last":"3,218.65","percChange":"2.86","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX PSE","previousClose":"3,063.25","open":"3,085.55","high":"3,096.50","low":"3,050.95","last":"3,091.95","percChange":"0.94","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX MNC","previousClose":"4,780.80","open":"4,791.15","high":"4,796.50","low":"4,748.65","last":"4,785.00","percChange":"0.09","indexOrder":".00"},{"timeVal":"Sep 15, 2011 16:01:17","indexName":"CNX PHARMA","previousClose":"4,528.80","open":"4,553.45","high":"4,558.95","low":"4,503.00","last":"4,543.85","percChange":"0.33","indexOrder":".00"}]}
EOF
end

def set_bhav_imported(date)
  stock = Stock.create
  EqQuote.create(stock: stock, date: date)
end
