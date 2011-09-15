require "spec_helper"

describe Importer::NiftyLiveImporter do
  describe 'UT' do
    before :each do
      http = stub()
      http.expects(:request_get).with('/homepage/Indices1.json', Importer::NseConnection.user_agent).returns(stub(:body => json_data))
      Net::HTTP.expects(:new).with(NSE_URL).returns(http)
      @date = Date.parse('13/09/2011')
      @stock = Stock.create!(symbol: 'NIFTY')
     end
    it "should import" do
      Importer::NiftyLiveImporter.new.import
      quote = EqQuote.find_by_stock_id_and_date(@stock.id, @date)
      quote.close.to_f.should == 4940.95
      quote.mov_avg_10d.should_not eq(0)
      quote.mov_avg_50d.should_not eq(0)
      quote.mov_avg_200d.should_not eq(0)
    end

    it "should update if quote already present" do
      EqQuote.create(stock: @stock, date: @date)

      Importer::NiftyLiveImporter.new.import
      quotes = EqQuote.find_all_by_stock_id_and_date(@stock.id, @date)
      quotes.size.should == 1
      quotes.first.close.to_f.should == 4940.95
    end
 end

  describe 'FT' do
    it "should import" do
      stock = Stock.create(symbol: 'NIFTY')
      Importer::NiftyLiveImporter.new.import
      EqQuote.find_all_by_stock_id(stock.id).size.should == 1
    end
  end
end

def json_data
<<EOF
{preOpen:"900",preClose:"908",mktOpen:"915",mktClose:"1530",corrOpen:"1550",corrClose:"1600",mktStatusCode:"5",status:"MARKET CLOSED",time:"Sep 13, 2011 16:01:43",data:[{name:"S&P CNX NIFTY Pre Open",lastPrice:"4,977.80",change:"31.00",pChange:"0.63",imgFileName:"S&P_CNX_NIFTY_Pre_Open_open.png"},{name:"S&P CNX NIFTY",lastPrice:"4,940.95",change:"-5.85",pChange:"-0.12",imgFileName:"S&P_CNX_NIFTY_open.png"},{name:"CNX NIFTY JUNIOR",lastPrice:"9,931.90",change:"-16.30",pChange:"-0.16",imgFileName:"CNX_NIFTY_JUNIOR_open.png"},{name:"BANK NIFTY",lastPrice:"9,339.70",change:"-55.55",pChange:"-0.59",imgFileName:"BANK_NIFTY_open.png"},{name:"INDIA VIX",lastPrice:"32.77",change:"0.02",pChange:"0.06",imgFileName:"INDIA_VIX_open.png"},{name:"CNX 100",lastPrice:"4,867.20",change:"-6.15",pChange:"-0.13",imgFileName:"CNX_100_open.png"},{name:"S&P CNX DEFTY",lastPrice:"3,601.30",change:"-38.85",pChange:"-1.07",imgFileName:"S&P_CNX_DEFTY_open.png"},{name:"S&P CNX 500",lastPrice:"4,007.10",change:"-3.65",pChange:"-0.09",imgFileName:"S&P_CNX_500_open.png"},{name:"CNX MIDCAP",lastPrice:"7,240.50",change:"4.90",pChange:"0.07",imgFileName:"CNX_MIDCAP_open.png"},{name:"NIFTY MIDCAP 50",lastPrice:"2,149.00",change:"-0.10",pChange:"0.00",imgFileName:"NIFTY_MIDCAP_50_open.png"},{name:"CNX INFRA",lastPrice:"2,734.90",change:"-8.15",pChange:"-0.30",imgFileName:"CNX_INFRA_open.png"},{name:"CNX REALTY",lastPrice:"230.60",change:"1.20",pChange:"0.52",imgFileName:"CNX_REALTY_open.png"},{name:"CNX ENERGY",lastPrice:"7,697.25",change:"21.70",pChange:"0.28",imgFileName:"CNX_ENERGY_open.png"},{name:"CNX FMCG",lastPrice:"10,047.05",change:"-1.45",pChange:"-0.01",imgFileName:"CNX_FMCG_open.png"},{name:"CNX MNC",lastPrice:"4,734.45",change:"11.20",pChange:"0.24",imgFileName:"CNX_MNC_open.png"},{name:"CNX PHARMA",lastPrice:"4,504.30",change:"-26.05",pChange:"-0.58",imgFileName:"CNX_PHARMA_open.png"},{name:"CNX PSE",lastPrice:"3,029.20",change:"-5.50",pChange:"-0.18",imgFileName:"CNX_PSE_open.png"},{name:"CNX PSU BANK",lastPrice:"3,126.60",change:"-24.50",pChange:"-0.78",imgFileName:"CNX_PSU_BANK_open.png"},{name:"CNX SERVICE",lastPrice:"5,797.40",change:"-9.55",pChange:"-0.16",imgFileName:"CNX_SERVICE_open.png"},{name:"CNX IT",lastPrice:"5,204.75",change:"46.90",pChange:"0.91",imgFileName:"CNX_IT_open.png"}]}
EOF


end