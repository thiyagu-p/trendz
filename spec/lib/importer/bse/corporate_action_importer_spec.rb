require 'spec_helper'

describe 'Importer::Bse::CorporateActionImporter' do

  describe 'FT' do

    it 'import from bse' do
      status = ImportStatus.find_or_create_by(source: ImportStatus::Source::BSE_CORPORATE_ACTION)
      status.update_attributes(data_upto: '12/07/2013')
      @lt = create(:stock, bse_code: 500510, symbol: 'LT')
      Date.expects(:today).times(3).returns(Date.parse('12/07/2013'))
      expect { Importer::Bse::CorporateActionImporter.new.import }.to change { BonusAction.count }.by(1)
    end
  end

  describe '.import' do

    before :each do
      @lt = create(:stock, bse_code: 500510, symbol: 'LT')
      agent = stub()
      Mechanize.expects(:new).returns(agent)
      page = stub()
      agent.expects(:get).with('http://www.bseindia.com/corporates/corporate_act.aspx').returns(page)
      @form = {}
      page.expects(:form).with('aspnetForm').returns(@form)
      data = stub()
      agent.expects(:submit).with(@form).returns(data)
      data.expects(:content).returns(bse_corp_action_data)
      status = ImportStatus.find_or_create_by(source: ImportStatus::Source::BSE_CORPORATE_ACTION)
      status.update_attribute(:data_upto, '20110102')
    end

    it 'should import, parse and save bonus data' do
      expect { Importer::Bse::CorporateActionImporter.new.import }.to change { BonusAction.count }.by(1)
    end

    it 'should import, parse and save error data' do
      expect { Importer::Bse::CorporateActionImporter.new.import }.to change { CorporateActionError.count }.by(1)
    end

    it 'should import, parse and save split data' do
      create(:stock, bse_code: 526209)
      expect { Importer::Bse::CorporateActionImporter.new.import }.to change { FaceValueAction.count }.by(1)
    end

    it 'should import, parse and save dividend data' do
      create(:stock, bse_code: 500114)
      expect { Importer::Bse::CorporateActionImporter.new.import }.to change { DividendAction.count }.by(1)
    end

    it 'should record last run date and status' do
      ImportStatus.failed ImportStatus::Source::BSE_CORPORATE_ACTION

      Importer::Bse::CorporateActionImporter.new.import

      status = ImportStatus.find_by(source: ImportStatus::Source::BSE_CORPORATE_ACTION)
      expect(status.completed).to be true
      expect(status.last_run).to eq Date.today
    end

    it 'should import from one day prior last completed date' do
      last_run_date = Date.parse('01/02/2013')
      data_upto = Date.parse('02/12/2012')

      status = ImportStatus.find_by(source: ImportStatus::Source::BSE_CORPORATE_ACTION)
      status.update_attributes(completed: true, last_run: last_run_date, data_upto: data_upto)

      Importer::Bse::CorporateActionImporter.new.import

      expect(@form['ctl00$ContentPlaceHolder1$txtDate']).to eq('01/12/2012')
    end

    it 'should import upto 90 days in future' do
      Importer::Bse::CorporateActionImporter.new.import

      expect(@form['ctl00$ContentPlaceHolder1$txtTodate']).to eq((Date.today + 90).strftime("%d/%m/%Y"))
    end

    it 'should skip already existing action' do
      create(:bonus_action, stock: @lt, ex_date: '11/07/2013', holding_qty: 2, bonus_qty: 1)
      expect { Importer::Bse::CorporateActionImporter.new.import }.not_to change { BonusAction.count }
    end
  end

  def bse_corp_action_data
    <<CSV
Scrip Code,Scrip Name,Ex Date,Purpose,Record Date,BC Start Date,BC End Date,ND Start Date,ND End Date
500114,TITAN,11 Jul 2007,Dividend - Rs.5.00,-,13 Jul 2007,27 Jul 2007,06 Jul 2007,12 Jul 2007
526209,KS Oils,18 Jul 2007,Stock  Split From Rs.10/- to Rs.1/-,25 Jul 2007,,,18 Jul 2007,24 Jul 2007
500510,L&amp;T,11 Jul 2013,BONUS 1:2,13 Jul 2013,,,-,-
999999,UNKNOWN,11 Jul 2013,BONUS 1:2,13 Jul 2013,,,-,-
500510,L&amp;T,01 Jul 2013,UNKNOWN 1:2,13 Jul 2013,,,-,-
CSV
  end


end
