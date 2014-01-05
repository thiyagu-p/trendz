require 'spec_helper'

describe Importer::Nse::StockMaster do

  before :each do
    ImportStatus.find_or_create_by(source: ImportStatus::Source::NSE_STOCK_MASTER)
    @importer = Importer::Nse::StockMaster.new
  end

  it "should import", ft: true  do
    @importer.import
    Stock.count.should > 0
    ongc = Stock.find_by(symbol: 'ONGC')
    ongc.name.should == 'Oil & Natural Gas Corporation Limited'
    ongc.face_value.should == 5
    ongc.isin.should == 'INE213A01029'
  end

  it 'should update symbol if isin matches to update existing bse listing or symbol change' do
    Stock.create!(symbol: '20MICRONS.BO', name: '20 Microns Limited', isin: 'INE144J01027')
    @importer.send(:parse_csv, bse_corp_action_data)
    stock = Stock.find_by(symbol: '20MICRONS')
    stock.should_not be_nil
    stock.nse_active.should be_true
  
    Stock.find_by(symbol: '20MICRONS.BO').should be_nil
    Stock.count.should == 1
  end
  
  it 'should create new stock' do
    @importer.send(:parse_csv, bse_corp_action_data)
    Stock.find_by(symbol: '20MICRONS').should_not be_nil
    Stock.count.should == 1
  end
  
  it 'should update existing stock' do
    Stock.create!(symbol: '20MICRONS')
    @importer.send(:parse_csv, bse_corp_action_data)
    Stock.count.should == 1
    stock = Stock.find_by(symbol: '20MICRONS')
    stock.isin.should == 'INE144J01027'
    stock.face_value.should == 5
    stock.name.should == '20 Microns Limited'
    stock.nse_series == 'EQ'
  end

end

def bse_corp_action_data
<<EOF
SYMBOL,NAME OF COMPANY, SERIES, DATE OF LISTING, PAID UP VALUE, MARKET LOT, ISIN NUMBER, FACE VALUE
20MICRONS,20 Microns Limited,EQ,06-OCT-2008,5,1,INE144J01027,5
EOF
end

