require 'spec_helper'
require 'zip/zipfilesystem'

describe Importer::Nse::EquityBhav do
  describe 'FT' do
    it 'should import' do
      stock = Stock.create! symbol: 'SPICEJET', bse_code: 500285
      date = Date.parse('07/02/2013')
      Importer::Bse::EquityBhav.new.send(:import_for, date)
      EqQuote.count.should == 1
      quote = EqQuote.find_by_stock_id_and_date stock.id, date
      quote.open.should == 44.40
      quote.high.should == 44.90
      quote.low.should == 43.00
      quote.close.should == 43.35
      quote.previous_close.should == 44.40
      quote.traded_quantity.should == 2351431
    end
  end

  describe 'UT' do
    before(:each) do
      @importer = Importer::Bse::EquityBhav.new
    end

    it 'should import starting from next day of last available' do
      @http = stub()
      Net::HTTP.expects(:new).with(BSE_URL).returns(@http)
      @import_status = ImportStatus.find_or_create_by_source(ImportStatus::Source::BSE_BHAV)

      @import_status.update_attributes! data_upto: Date.parse('1/2/2010')
      Date.stubs(:today).returns(Date.parse('4/2/2010'))
      @http.expects(:request_get).with('/download/BhavCopy/Equity/eq020210_csv.zip').returns(stub(:class => Net::HTTPNotFound))
      @http.expects(:request_get).with('/download/BhavCopy/Equity/eq030210_csv.zip').returns(stub(:class => Net::HTTPNotFound))
      @http.expects(:request_get).with('/download/BhavCopy/Equity/eq040210_csv.zip').returns(stub(:class => Net::HTTPNotFound))
      @importer.import
    end

    it 'should skip stocks which does not already existing' do
      row = stub()
      row.stubs(:fields).returns('500285,SPICEJET LTD,B ,Q,44.40,44.90,43.00,43.35,43.35,44.40,6457,2351431,103229115.00,'.split(','))
      @importer.send(:process_row, row, Date.today)
      EqQuote.count.should == 0
      Stock.create! symbol: 'SPICEJET', bse_code: 500285
      @importer.send(:process_row, row, Date.today)
      EqQuote.count.should == 1
    end

    it 'should not save quotes which is already imported from nse' do
      stock = Stock.create! symbol: 'SPICEJET', bse_code: 500285
      date = Date.today
      EqQuote.create! stock: stock, date: date, open: 1, high: 1, low: 1, close: 1, previous_close: 1, traded_quantity: 1

      row = stub()
      row.stubs(:fields).returns('500285,SPICEJET LTD,B ,Q,44.40,44.90,43.00,43.35,43.35,44.40,6457,2351431,103229115.00,'.split(','))
      @importer.send(:process_row, row, date)
      EqQuote.count.should == 1

      EqQuote.first.open.should == 1
    end

    it 'should update import status on successful completion of import' do
      ImportStatus.create!(source: ImportStatus::Source::BSE_BHAV)
      Zip::ZipFile.stubs(:open)
      date = Date.parse('1/1/2013')
      @importer.send(:parse_bhav_file, '', '', date)
      ImportStatus.find_or_create_by_source(ImportStatus::Source::BSE_BHAV).data_upto.should == date
    end

    it 'should update import status on successful completion of import' do
      old_date = Date.parse('31/12/2012')
      ImportStatus.create!(source: ImportStatus::Source::BSE_BHAV, data_upto: old_date)
      Zip::ZipFile.stubs(:open).raises(Zip::ZipError.new)
      @importer.send(:parse_bhav_file, '', '', Date.parse('1/1/2013'))
      ImportStatus.find_by_source(ImportStatus::Source::BSE_BHAV).data_upto.should == old_date
    end
  end
end