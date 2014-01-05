require 'spec_helper'
require 'csv'

describe Importer::YahooData do

  before(:each) do
    @http = stub()
    Net::HTTP.expects(:new).with(Importer::YahooData::BASEURL).returns(@http)
    @importer = Importer::YahooData.new
    ImportStatus.find_or_create_by(source: ImportStatus::Source::YAHOO_QUOTES)
  end

  it "should import quotes for all stocks which has yahoo code set" do
    Date.stubs(:today).returns(Date.parse('2/1/2011'))

    create(:stock, symbol: 'Symbol1', yahoo_code: '^Y1')
    create(:stock, symbol: 'Symbol2', yahoo_code: 'Y2')
    create(:stock, symbol: 'Symbol3')

    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=0&b=1&c=2011&d=0&e=2&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))
    @http.expects(:request_get).with('/table.csv?&s=Y2&a=0&b=1&c=2011&d=0&e=2&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should import quote from next day of last available date of specific stock which has open price" do
    Date.stubs(:today).returns(Date.parse('5/10/2009'))
    stock = create(:stock, symbol: 'Symbol1', yahoo_code: '^Y1')
    create(:eq_quote, stock: stock, date: Date.parse('1/1/2009'))
    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=0&b=2&c=2009&d=9&e=5&f=2009&g=d&ignore=.csv').returns(stub(:class => Net::HTTPNotFound))

    @importer.import
  end

  it "should update data for specific date if already present" do
    Date.stubs(:today).returns(Date.parse('2011-08-31'))
    stock = create(:stock, symbol: 'Symbol1', yahoo_code: '^Y1')
    date = Date.parse('2011-08-30')
    create(:eq_quote, stock: stock, date: date)
    create(:eq_quote, stock: stock, date: date + 1, traded_quantity: nil)

    @http.expects(:request_get).with('/table.csv?&s=%5EY1&a=7&b=31&c=2011&d=7&e=31&f=2011&g=d&ignore=.csv').returns(stub(:class => Net::HTTPOK, :body => data))

    @importer.import
    quotes = EqQuote.where(stock_id: stock.id, date: date).to_a
    quotes.size.should == 1
    expect(quotes.first.open).to be_within(0.01).of(1209.76)
    expect(quotes.first.high).to be_within(0.01).of(1220.10)
    expect(quotes.first.low).to be_within(0.01).of(1195.77)
    expect(quotes.first.close).to be_within(0.01).of(1212.92)
  end

  it "should import skipping header and calculate moving average" do
    stock = create(:stock, symbol: 'Symbol1', yahoo_code: '^Y1')
    @http.expects(:request_get).returns(stub(:class => Net::HTTPOK, :body => data))

    @importer.import

    EqQuote.where(stock_id: stock.id).to_a.size.should == 5
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