require "spec_helper"

describe Importer::CorporateActionImporter do

  it "should import for all equity stocks" do
    stock1 = Stock.create(symbol: 'RELIANCE', series: Stock::Series::EQUITY)
    stock2 = Stock.create(symbol: 'TCS', series: Stock::Series::EQUITY)
    index1 = Stock.create(symbol: 'NIFTY', series: Stock::Series::INDEX)
    @http = stub()
    Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
    @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock1.symbol}", Importer::NseConnection.user_agent).returns(stub(:class => Net::HTTPNotFound))
    @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock2.symbol}", Importer::NseConnection.user_agent).returns(stub(:class => Net::HTTPNotFound))
    Importer::CorporateActionImporter.new.import
  end

  it "should encode symbol" do
    Stock.create(symbol: 'M&M', series: Stock::Series::EQUITY)
    @http = stub()
    Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
    #@http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=M%26M", Importer::NseConnection.user_agent).returns(stub(:class => Net::HTTPNotFound))
    @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=M%26M", Importer::NseConnection.user_agent).returns(stub(body: open('corp.html').read))
    Importer::CorporateActionImporter.new.import
  end

  it "should include only EQ series" do

  end
  it "should import dividents" do

  end

  it "should import splits" do

  end

  it "should import bonus" do

  end

  it "should import merger" do

  end

  it "should import demerger" do

  end

end