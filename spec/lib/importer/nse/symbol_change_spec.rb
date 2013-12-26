require 'spec_helper'

describe Importer::Nse::SymbolChange do
  before(:each) do
    @http = stub()
    Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
    ImportStatus.find_or_create_by(source: ImportStatus::Source::NSE_SYMBOL_CHANGE)
    @importer = Importer::Nse::SymbolChange.new
    response = stub(:body => response_data )
    @http.expects(:request_get).with('/content/equities/symbolchange.csv', Importer::Nse::Connection.user_agent).returns(response)
  end

  describe 'Symbol changes for non existing new symbols' do
    it "should apply symbol change" do
      Stock.create!(:symbol => 'BIRLA3M')
      @importer.import
      Stock.find_by_symbol('BIRLA3M').should be_nil
      Stock.find_by_symbol('3MINDIA').should_not be_nil
    end

    it "should handle multiple symbol changes for same symbol in datewise order" do
      Stock.create!(:symbol => 'TATATELECM')
      @importer.import
      Stock.find_by_symbol('TATATELECM').should be_nil
      Stock.find_by_symbol('AVAYAGCL').should be_nil
      Stock.find_by_symbol('AGCNET').should_not be_nil
    end
  end

  describe 'Symbol changes for existing new symbols ' do
    before(:each) do
      @old_stock = Stock.create!(:symbol => 'BIRLA3M')
      @new_stock = Stock.create!(:symbol => '3MINDIA')
      @today = Date.parse('15-JUN-2004')
      @yesterday = Date.parse('14-JUN-2004')
      Date.stubs(:today).returns(@today)
    end

    it "should have only new stock symbol" do
      @importer.import
      Stock.find_by_symbol(@old_stock.symbol).should be_nil
      Stock.where(symbol: @new_stock.symbol).to_a.size.should == 1
    end

    it "should update old stock and delete new stock" do
      @importer.import
      Stock.find_by(symbol: @old_stock.symbol).should be_nil
      Stock.find_by(symbol: @new_stock.symbol).id.should == @old_stock.id
    end

    it "should merge new stocks equity quotes to old stock" do
      EqQuote.create!(:stock => @old_stock, :date => @yesterday)
      EqQuote.create!(:stock => @new_stock, :date => @today)

      @importer.import

      EqQuote.where(stock_id: @new_stock.id).to_a.size.should == 0
      EqQuote.where(stock_id: @old_stock.id).to_a.size.should == 2
      EqQuote.where(stock_id: @old_stock.id, date: @yesterday).should_not be_nil
      EqQuote.where(stock_id: @old_stock.id, date: @today).should_not be_nil
    end

    it "should recalculate moving averages for quotes merged from new stock" do
      EqQuote.create!(:stock => @old_stock, :date => @yesterday, :close => 10)
      original_moving_avg = 1000
      EqQuote.create!(:stock => @new_stock, :date => @today, :close => 20, :mov_avg_10d => original_moving_avg, :mov_avg_50d => original_moving_avg, :mov_avg_200d => original_moving_avg)

      @importer.import

      quote = EqQuote.find_by(stock_id: @old_stock.id, date: @today)
      quote.mov_avg_10d.should_not == original_moving_avg
      quote.mov_avg_50d.should_not == original_moving_avg
      quote.mov_avg_200d.should_not == original_moving_avg
    end
  end

  def response_data
<<EOF
SYMB_COMPANY_NAME, SM_KEY_SYMBOL, SM_NEW_SYMBOL, SM_APPLICABLE_FROM
3M India Limited,BIRLA3M,3MINDIA,15-JUN-2004
AGC Networks Limited,AVAYAGCL,AGCNET,08-JUN-2010
AGC Networks Limited,TATATELECM,AVAYAGCL,01-NOV-2004


**This file is updated at 10:30 am everyday.
EOF
  end
end