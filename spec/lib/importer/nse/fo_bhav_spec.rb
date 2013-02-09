require 'spec_helper'
require 'csv'

describe Importer::Nse::FoBhav do

  before :all do
    @importer = Importer::Nse::FoBhav.new
    @stock = Stock.create(symbol: 'BANKNIFTY', nse_series: Stock::NseSeries::INDEX)
  end

  describe :import do
    it "should import future" do
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,30-Jun-2011,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,24-JUN-2011,'))
      FoQuote.count.should == 1
      quote = FoQuote.find_by_stock_id(@stock.id)
      quote.open.should == 10616.1
      quote.high.should == 10897.5
      quote.low.should == 10611
      quote.close.should == 10880.8
      quote.traded_quantity.should == 61910
      quote.open_interest.should == 963575
      quote.change_in_open_interest.should == -193375
      quote.expiry_date.should == Date.parse('30-Jun-2011')
      quote.date.should == Date.parse('24-Jun-2011')
      quote.fo_type.should == 'XX'
    end

    it "should import options" do
      @importer.process_row(CSV.parse_line('OPTIDX,BANKNIFTY,30-Jun-2011,5200,CE,186.5,186.5,186.5,186.5,186.5,1,1.07,100,-20,24-JUN-2011,'))
      FoQuote.count.should == 1
      quote = FoQuote.find_by_stock_id(@stock.id)
      quote.fo_type.should == 'CE'
      quote.strike_price.should == 5200
    end

    it "should create missing index and import" do
      @importer.process_row(CSV.parse_line('OPTIDX,MININIFTY,30-Jun-2011,5200,CE,186.5,186.5,186.5,186.5,186.5,1,1.07,100,-20,24-JUN-2011,'))
      FoQuote.count.should == 1
      Stock.find_by_symbol('MININIFTY').nse_series.should == Stock::NseSeries::INDEX
    end

    it "should create missing stock and import" do
      @importer.process_row(CSV.parse_line('OPTSTK,LICHSGFIN,30-Jun-2011,5200,CE,186.5,186.5,186.5,186.5,186.5,1,1.07,100,-20,24-JUN-2011,'))
      FoQuote.count.should == 1
      Stock.find_by_symbol('LICHSGFIN').nse_series.should == Stock::NseSeries::EQUITY
    end

    it "should skip if it is not traded" do
      @importer.process_row(CSV.parse_line('OPTIDX,BANKNIFTY,30-Jun-2011,12000,PE,0,0,0,1097.8,1127.45,0,0,1625,0,24-JUN-2011,'))
      FoQuote.count.should == 0
    end

    it "should skip header row" do
      @importer.process_row(CSV.parse_line('INSTRUMENT,SYMBOL,EXPIRY_DT,STRIKE_PR,OPTION_TYP,OPEN,HIGH,LOW,CLOSE,SETTLE_PR,CONTRACTS,VAL_INLAKH,OPEN_INT,CHG_IN_OI,TIMESTAMP,'))
      FoQuote.count.should == 0
    end
  end

  describe :identify_series do

    it "should identify current for expiry of this month" do
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,30-Jun-2011,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,24-JUN-2011,'))
      FoQuote.find_by_stock_id(@stock.id).expiry_series.should == FoQuote::ExpirySeries::CURRENT
    end

    it "should identify current for expiry of next month but past current month expiry date" do
      FoQuote.create!(stock: @stock, expiry_date: Date.parse('28-Jul-2011'))
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,25-Aug-2011,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,29-Jul-2011,'))
      FoQuote.find_by_stock_id(@stock.id).expiry_series.should == FoQuote::ExpirySeries::CURRENT
    end
    it "should identify next" do
      FoQuote.create!(stock: @stock, expiry_date: Date.parse('30-Jun-2011'))
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,28-Jul-2011,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,24-JUN-2011,'))
      FoQuote.find_by_stock_id(@stock.id).expiry_series.should == FoQuote::ExpirySeries::NEXT
    end
    it "should identify far" do
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,25-Aug-2011,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,24-JUN-2011,'))
      FoQuote.find_by_stock_id(@stock.id).expiry_series.should == FoQuote::ExpirySeries::FAR
    end
    it "should identify unknow" do
      @importer.process_row(CSV.parse_line('FUTIDX,BANKNIFTY,30-Jun-2012,0,XX,10616.1,10897.5,10611,10880.8,10880.8,61910,166889.6,963575,-193375,24-JUN-2011,'))
      FoQuote.find_by_stock_id(@stock.id).expiry_series.should == FoQuote::ExpirySeries::UNKNOWN
    end
  end
end