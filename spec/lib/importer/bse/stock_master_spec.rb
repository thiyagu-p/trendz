require 'spec_helper'

describe Importer::Bse::StockMaster do

  before :each do
    ImportStatus.find_or_create_by(source: ImportStatus::Source::BSE_STOCKMASTER)
    @importer =  Importer::Bse::StockMaster.new
  end

  #it "should import", ft: true do
  #  Importer::Bse::StockMaster.new.import
  #  Stock.count.should > 0
  #
  #  ongc = Stock.find_by_symbol 'ONGC.BO'
  #  ongc.name.should == 'OIL AND NATURAL GAS CORPORATION LTD.'
  #  ongc.face_value.should == 5
  #  ongc.isin.should == 'INE213A01029'
  #  ongc.industry.should == 'Exploration &amp; Production'
  #  ongc.bse_code.should == 500312
  #  ongc.bse_group.should == 'A'
  #  ongc.bse_active.should be_true
  #end

  #500285	SPICEJET	SPICEJET LTD.	Active	B 	10	INE285B01017	Airlines

  it 'should import stock' do
    @importer.send(:process_csv, bse_csv_content)
    Stock.count.should == 2
  end

  it 'should create missing stock with Bse Symbol as Symbol' do
    @importer.send(:process_csv, bse_csv_content)
    stock = Stock.find_by_symbol 'ASSAMCO_BO'
    stock.bse_code.should == 500024
    stock.bse_symbol.should == 'ASSAMCO'
    stock.name.should == 'Assam Company (India) Limited'
    stock.face_value.should ==  1
    stock.isin.should ==  'INE442A01024'
    stock.industry.should == 'Tea &amp; Coffee'
    stock.bse_active.should be_true
  end

  it 'should update listing status' do
    @importer.send(:process_csv, bse_csv_content)
    Stock.find_by_symbol('ASSAMCO_BO').bse_active.should be_true
    Stock.find_by_symbol('ATULLTD_BO').bse_active.should be_false

  end

  it 'should update existing stock' do
     Stock.create!(symbol: 'ASSAMCO_NS', isin: 'INE442A01024', nse_active: true, is_equity: true)
     @importer.send(:process_csv, bse_csv_content)
     stock = Stock.where(symbol: 'ASSAMCO_NS').first
     expect(stock.bse_code).to be(500024)
     expect(stock.bse_symbol).to eq('ASSAMCO')
  end

  it 'should skip stocks without isin' do
    @importer.send(:process_csv, bse_csv_content)
    Stock.find_by_symbol('NOISIN.BO').should be_nil
  end

end

def bse_csv_content
<<EOF
Scrip Code,Scrip Id,Scrip Name,Status,Group,Face Value,ISIN No,Industry,Instrument
500024,ASSAMCO,Assam Company (India) Limited,Active,B ,1.00,INE442A01024,Tea &amp; Coffee,Equity
500027,ATULLTD,ATUL LTD.,Delisted,B ,10.00,INE100A01010,Agrochemicals,Equity
500000,NOISIN,ATUL LTD.,Delisted,B ,10.00,NA,Agrochemicals,Equity
EOF
end
