require 'spec_helper'
require 'csv'

describe Importer::YahooData do

  before(:all) do
    @importer = Importer::YahooData.new
  end

  it "should import quotes for all stocks which has yahoo code set" do
    Date.stubs(:today).returns(Date.parse('2/1/2009'))

    Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    Stock.create(symbol: 'Symbol2', yahoo_code: 'Y2')
    Stock.create(symbol: 'Symbol3')

    Net::HTTP.expects(:get_response).with(Importer::YahooData::BASEURL, '/table.csv?&s=%5EY1&a=0&b=1&c=2007&d=0&e=2&f=2009&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))
    Net::HTTP.expects(:get_response).with(Importer::YahooData::BASEURL, '/table.csv?&s=Y2&a=0&b=1&c=2007&d=0&e=2&f=2009&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should import quote from next day of last available date of specific stock" do
    Date.stubs(:today).returns(Date.parse('5/10/2009'))

    stock = Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    EqQuote.expects(:maximum).with(:date, :conditions => "stock_id = #{stock.id}").returns(Date.parse('1/1/2009'))
    Net::HTTP.expects(:get_response).with(Importer::YahooData::BASEURL, '/table.csv?&s=%5EY1&a=0&b=2&c=2009&d=9&e=5&f=2009&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should import skipping header and calculate moving average" do
    stock = Stock.create(symbol: 'Symbol1', yahoo_code: '^Y1')
    Net::HTTP.expects(:get_response).returns(stub(:class => Net::HTTPOK, :body => data))

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