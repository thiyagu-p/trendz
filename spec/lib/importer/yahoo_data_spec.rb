require 'spec_helper'
require 'csv'

describe Importer::YahooData do

  before(:each) do
    @http = stub()
    Net::HTTP.expects(:new).with(Importer::YahooData::BASEURL).returns(@http)
    @importer = Importer::YahooData.new
    ImportStatus.find_or_create_by_source(ImportStatus::Source::YAHOO_QUOTES)
  end

  it "should import quotes for all stocks which has yahoo code set" do
    Date.stubs(:today).returns(Date.parse('2/1/2011'))

    Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    Stock.create(symbol: 'Symbol2', yahoo_code: 'Y2')
    Stock.create(symbol: 'Symbol3')

    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=0&b=1&c=2011&d=0&e=2&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))
    @http.expects(:request_get).with('/table.csv?&s=Y2&a=0&b=1&c=2011&d=0&e=2&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should import quote from next day of last available date of specific stock which has open price" do
    Date.stubs(:today).returns(Date.parse('5/10/2009'))

    stock = Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    EqQuote.expects(:maximum).with(:date, :conditions => "stock_id = #{stock.id} and traded_quantity is not null").returns(Date.parse('1/1/2009'))
    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=0&b=2&c=2009&d=9&e=5&f=2009&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should update data for specific date if already present" do
    Date.stubs(:today).returns(Date.parse('2011-08-30'))
    stock = Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    date = Date.parse('2011-08-30')
    EqQuote.create(stock_id: stock.id, date: date)
    EqQuote.expects(:maximum).with(:date, :conditions => "stock_id = #{stock.id} and traded_quantity is not null").returns(date - 1)
    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=7&b=30&c=2011&d=7&e=30&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPOK, :body => data))

    @importer.import
    quotes = EqQuote.find_all_by_stock_id_and_date(stock.id, date)
    quotes.size.should == 1
    quotes.first.open.should == 1209.76
    quotes.first.high.should == 1220.10
    quotes.first.low.should == 1195.77
    quotes.first.close.should == 1212.92
  end

  it "should import skipping header and calculate moving average" do
    stock = Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    @http.expects(:request_get).returns(stub(:class => Net::HTTPOK, :body => data))

    @importer.import

    EqQuote.find_all_by_stock_id(stock.id).size.should == 5
    quote = EqQuote.find_by_stock_id_and_date(stock.id, Date.parse('30/8/2011'))
    quote.open.should == 1209.76
    quote.high.should == 1220.10
    quote.low.should == 1195.77
    quote.close.should == 1212.92
    quote.traded_quantity.should == 4572570000
    quote.mov_avg_10d.to_f.should == 1187.33
    quote.mov_avg_50d.to_f.should == 1187.33
    quote.mov_avg_200d.to_f.should == 1187.33
  end
end

def data
<<EOF
Date,Open,High,Low,Close,Volume,Adj Close
2011-08-30,1209.76,1220.10,1195.77,1212.92,4572570000,1212.92
2011-08-29,1177.91,1210.28,1177.91,1210.08,4228070000,1210.08
2011-08-26,1158.85,1181.23,1135.91,1176.80,5035320000,1176.80
2011-08-25,1176.69,1190.68,1155.47,1159.27,5748420000,1159.27
2011-08-24,1162.16,1178.56,1156.30,1177.60,5315310000,1177.60
EOF
end