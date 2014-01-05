require "spec_helper"

describe Importer::Nse::CorporateActionImporter do
  before :each do
    @status = ImportStatus.find_or_create_by(source: ImportStatus::Source::NSE_CORPORATE_ACTION)
  end

  describe '.more_than_24_months_url' do
    it 'should encode url' do
      Importer::Nse::CorporateActionImporter.more_than_24_months_url('M&M').should == '/corporates/datafiles/CA_M%26M_MORE_THAN_24_MONTHS.csv'
    end
  end

  describe '.import' do

    context 'first time run' do
      it 'import one by one using more than 24 months data and future data' do
        reliance = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY, nse_active: true)
        lt = Stock.create(symbol: 'LT', nse_series: Stock::NseSeries::EQUITY, nse_active: true)
        @http = stub()
        Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(reliance.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(lt.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: ''))
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))

        Importer::Nse::CorporateActionImporter.new.import

        expect(BonusAction.count).to be 1
      end
    end

    context 'updating within 15 days' do
      it 'import using last 15 days data and future data' do
        reliance = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY, nse_active: true)
        @status.update_attributes!(data_upto: Date.today - 14)
        @http = stub()
        Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::LAST_15_DAYS, Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))

        Importer::Nse::CorporateActionImporter.new.import
        expect(BonusAction.count).to be 1
      end
    end

    context 'updating within 3 months' do
      it 'import using last 3 months data' do
        reliance = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY, nse_active: true)
        @status.update_attributes!(data_upto: Date.today - 89)
        @http = stub()
        Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::LAST_3_MONTHS, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))

        Importer::Nse::CorporateActionImporter.new.import
        expect(BonusAction.count).to be 1
      end
    end

    context 'parsing of data' do
      before :each do
        @stock1 = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY, nse_active: true )
        @http = stub()
        Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(@stock1.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
        @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
        Importer::Nse::CorporateActionImporter.new.import
      end

      describe :dividend do

        it 'should import and save dividend' do
          dividend = DividendAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('31/05/2012')
          dividend.should_not be_nil
          dividend.nature.should == 'DIVIDEND'
        end

        it 'should save percentage dividend as it is' do
          dividend = DividendAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('31/05/2011')
          dividend.percentage.should == 90
        end

        it 'should skip existing dividend' do
          Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(@stock1.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
          @status.update_attributes!(data_upto: Date.today - 1000)
          expect { Importer::Nse::CorporateActionImporter.new.import }.to change(DividendAction, :count).by(0)
        end

        it 'should handle other type of dividend' do
          dividend = DividendAction.find_by_stock_id_and_ex_date_and_nature @stock1.id, Date.parse('31/05/2010'), 'INTERIM'
          dividend.percentage.should == 90
          dividend = DividendAction.find_by_stock_id_and_ex_date_and_nature @stock1.id, Date.parse('31/05/2010'), 'FINAL'
          dividend.percentage.should == 100
          dividend = DividendAction.find_by_stock_id_and_ex_date_and_nature @stock1.id, Date.parse('31/05/2010'), 'SPECIAL'
          dividend.percentage.should == 120
        end

        it 'should not skip dividend if value is same but type is different' do
          dividend = DividendAction.find_by_stock_id_and_ex_date_and_nature @stock1.id, Date.parse('31/05/2009'), 'INTERIM'
          dividend.percentage.should == 10
          dividend = DividendAction.find_by_stock_id_and_ex_date_and_nature @stock1.id, Date.parse('31/05/2009'), 'FINAL'
          dividend.percentage.should == 10
        end
      end

      describe :bonus do
        it 'should import and save bonus' do
          bonus = BonusAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('1/06/2008')
          bonus.should_not be_nil
          bonus.holding_qty.should == 3
          bonus.bonus_qty.should == 2
        end

        it 'should skip existing bonus' do
          Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(@stock1.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
          @status.update_attributes!(data_upto: Date.today - 1000)
          expect { Importer::Nse::CorporateActionImporter.new.import }.to change(BonusAction, :count).by(0)
        end
      end

      describe :split do
        it 'should import and save split' do
          split = FaceValueAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('1/06/2007')
          split.should_not be_nil
          split.from.should == 10
          split.to.should == 2
        end

        it 'should skip existing split action' do
          Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(@stock1.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
          @status.update_attributes!(data_upto: Date.today - 1000)
          expect { Importer::Nse::CorporateActionImporter.new.import }.to change(BonusAction, :count).by(0)
        end
      end

      describe :consolidation do
        it 'should import and save consolidation' do
          consolidation = FaceValueAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('1/06/2005')
          consolidation.should_not be_nil
          consolidation.from.should == 1
          consolidation.to.should == 10
        end
      end

      describe :error do
        it 'should import and save ignored actions' do
          corporate_action_error = CorporateActionError.find_by_stock_id_and_ex_date @stock1.id, Date.parse('31/05/2011')
          corporate_action_error.should_not be_nil
          corporate_action_error.full_data.should == 'ANNUAL GENERAL MEETING AND DIVIDEND 90%'
          corporate_action_error.partial_data.should == 'ANNUAL GENERAL MEETING'
          corporate_action_error.is_ignored.should be_true
        end

        it 'should import and save unknown actions' do
          corporate_action_error = CorporateActionError.find_by_stock_id_and_ex_date @stock1.id, Date.parse('31/05/2012')
          corporate_action_error.should_not be_nil
          corporate_action_error.full_data.should == 'ERROR AND DIVIDEND RS.8.50 PER SHARE'
          corporate_action_error.partial_data.should == 'ERROR'
          corporate_action_error.is_ignored.should be_false
        end

        it 'should import and save multiple unknown actions' do
          corporate_action_errors = CorporateActionError.where(stock_id: @stock1.id, ex_date: Date.parse('01/06/2004')).to_a
          corporate_action_errors.count.should == 2
        end

        it 'should skip existing ignored actions' do
          Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter.more_than_24_months_url(@stock1.symbol), Importer::Nse::Connection.user_agent).returns(stub(body: corporate_action_json))
          @http.expects(:request_get).with(Importer::Nse::CorporateActionImporter::FORTHCOMING_URL, Importer::Nse::Connection.user_agent).returns(stub(body: ''))
          @status.update_attributes!(data_upto: Date.today - 1000)
          expect { Importer::Nse::CorporateActionImporter.new.import }.to change(BonusAction, :count).by(0)
        end
      end

      it 'should ignore non equity actions' do
        bonus = BonusAction.find_by_stock_id_and_ex_date @stock1.id, Date.parse('1/06/2006')
        bonus.should be_nil
      end
    end
  end

  describe :ex_date do
    it 'should use ex_date if exist' do
      data = '"RELIANCE","RIL","-","EQ","10","A","31-May-2012","-","08-Jul-2005","19-Jul-2005","-","-"'.split(',')
      Importer::Nse::CorporateActionImporter.new.send(:find_ex_date, data).should == Date.parse('31/05/2012')
    end

    it 'should use record_date if ex_date missing' do
      data = '"RELIANCE","RIL","-","EQ","10","A","-","02-Jun-2012","08-Jul-2005","19-Jul-2005","-","-"'.split(',')
      Importer::Nse::CorporateActionImporter.new.send(:find_ex_date, data).should == Date.parse('01/06/2012')
    end

    it 'should use BC Start date if exdate and record date missing' do
      data = '"RELIANCE","RIL","-","EQ","10","A","-", "-", "02-Jun-2012","19-Jul-2005","-","-"'.split(',')
      Importer::Nse::CorporateActionImporter.new.send(:find_ex_date, data).should == Date.parse('01/06/2012')
    end
  end

  describe :parse_action do
    it 'should parse value divident' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIVIDEND RS 1.80 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '1.80'}
      importer.send(:parse_action, 'DIVIDEND RS1.80 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '1.80'}
      importer.send(:parse_action, 'DIVIDEND RS 10 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '10'}
      importer.send(:parse_action, 'DIVIDEND RS10 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '10'}
      importer.send(:parse_action, 'DIVIDEND RS.10 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '10'}
      importer.send(:parse_action, 'DIVIDEND RS.4.50 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '4.50'}
      importer.send(:parse_action, 'DIVIDEND-RE.0.20 PER SHARE').first.should == {type: :dividend, :nature => :DIVIDEND, value: '0.20'}
      importer.send(:parse_action, 'DV-RE.1 PR SH').first.should == {type: :dividend, :nature => :DIVIDEND, value: '1'}
      importer.send(:parse_action, 'Div.-Re.1/- Per Share').first.should == {type: :dividend, :nature => :DIVIDEND, value: '1'}
    end
    it 'should ignore nil divident' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIVIDEND-NIL').first.should == {type: :ignore, data: 'DIVIDEND-NIL'}
    end
    it 'should parse percentage divident' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIVIDEND-120%').first.should == {type: :dividend, :nature => :DIVIDEND, percentage: '120'}
      importer.send(:parse_action, 'DIVIDEND - 17.50%').first.should == {type: :dividend, :nature => :DIVIDEND, percentage: '17.50'}
    end
    it 'should parse combined value dividents' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIV-FIN RS.1.5+INT RS.2.1PURPOSE REVISED').should == [{type: :dividend, :nature => :FINAL, value: '1.5'}, {type: :dividend, :nature => :INTERIM, value: '2.1'}]
      importer.send(:parse_action, 'DIVIDEND - FINAL RS 22 + SPECIAL RS 10').should == [{type: :dividend, :nature => :FINAL, value: '22'}, {type: :dividend, :nature => :SPECIAL, value: '10'}]
      importer.send(:parse_action, 'DIV-FIN RE0.25+SPL RE0.35').should == [{type: :dividend, :nature => :FINAL, value: '0.25'}, {type: :dividend, :nature => :SPECIAL, value: '0.35'}]
      importer.send(:parse_action, 'DIV-RS10+GLD JUB-RS12.1').should == [{type: :dividend, :nature => :DIVIDEND, value: '10'}, {type: :dividend, :nature => :UNKNOWN, value: '12.1'}]
    end
    it 'should parse combined percentage dividents' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIV-50% + SPL DIV-60%').should == [{type: :dividend, :nature => :DIVIDEND, percentage: '50'}, {type: :dividend, :nature => :SPECIAL, percentage: '60'}]
      importer.send(:parse_action, 'DIV.-FIN.75%+SPL.25%').should == [{type: :dividend, :nature => :FINAL, percentage: '75'}, {type: :dividend, :nature => :SPECIAL, percentage: '25'}]
      importer.send(:parse_action, 'DIV-(FIN-100%+SP-30%)').should == [{type: :dividend, :nature => :FINAL, percentage: '100'}, {type: :dividend, :nature => :SPECIAL, percentage: '30'}]
      importer.send(:parse_action, 'FINALDIV.-10%+SPL.DIV.-5%').should == [{type: :dividend, :nature => :FINAL, percentage: '10'}, {type: :dividend, :nature => :SPECIAL, percentage: '5'}]
    end

    it 'should parse split' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'FV SPLIT RS.10/- TO RS.1/').should == [{type: :split, from: '10', to: '1'}]
      importer.send(:parse_action, 'FV SPLIT RS 10 TO RS 1').should == [{type: :split, from: '10', to: '1'}]
      importer.send(:parse_action, 'FV SPLIT RS.10 TO RS.5').should == [{type: :split, from: '10', to: '5'}]
      importer.send(:parse_action, 'Fv Split Rs.10 To Re.1').should == [{type: :split, from: '10', to: '1'}]
      importer.send(:parse_action, 'SPL RS10-RS2').should == [{type: :split, from: '10', to: '2'}]
    end

    it 'should parse consolidation' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'CONSOLIDATION RE1 TO RS10').should == [{type: :consolidation, from: '1', to: '10'}]
      importer.send(:parse_action, 'CONSOLIDATION RE.1/- TO RS.10/-').should == [{type: :consolidation, from: '1', to: '10'}]
      importer.send(:parse_action, 'Consolidation Re1 To Rs10').should == [{type: :consolidation, from: '1', to: '10'}]
    end

    it 'should parse bonus' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'BONUS 2:1').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.send(:parse_action, 'BON-2:1').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.send(:parse_action, 'BONUS28:100').should == [{type: :bonus, bonus: '28', holding: '100'}]
    end

    it 'should handle multiple actions split by AND' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'BONUS 22:1 AND FACE VALUE SPLIT FROM RS.10/- TO RE.1/').should ==
          [{type: :bonus, bonus: '22', holding: '1'}, {type: :split, from: '10', to: '1'}]
      importer.send(:parse_action, 'Bonus 1:1 And Face Value Split From Rs.10/- To Rs.5/-').should ==
          [{type: :bonus, bonus: '1', holding: '1'}, {type: :split, from: '10', to: '5'}]
      importer.send(:parse_action, 'DIVIDEND RS.6/- PER SHARE AND FACE VALUE SPLIT FROM RS.2/- TO RE.1/-').should ==
          [{type: :dividend, :nature => :DIVIDEND, value: '6'}, {type: :split, from: '2', to: '1'}]
      importer.send(:parse_action, 'BONUS - 1:1 AND FACE VALUE SPLIT FROM RS. 10 TO RS. 2').should ==
          [{type: :bonus, bonus: '1', holding: '1'}, {type: :split, from: '10', to: '2'}]
      importer.send(:parse_action, 'BONUS 1:2 AND FACE VALUE SPLIT FROM RS.10 TO RS.2').should ==
          [{type: :bonus, bonus: '1', holding: '2'}, {type: :split, from: '10', to: '2'}]
      importer.send(:parse_action, 'INTERIM DIVIDEND RS.3/- PER SHARE AND FACE VALUE SPLIT FROM RS.5/- TO RS.2/- (PURPOSE REVISED)').should ==
          [{type: :dividend, :nature => :INTERIM, value: '3'}, {type: :split, from: '5', to: '2'}]
    end

    it 'should handle multiple actions split by / and AND' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'BONUS 22:1 / FINAL DIVIDEND RS 0.60  AND SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'}, {type: :dividend, :nature => :FINAL, value: '0.60'}, {type: :dividend, :nature => :SPECIAL, value: '1.40'}]
      importer.send(:parse_action, 'BONUS 22:1 AND FINAL DIVIDEND RS 0.60  + SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'}, {type: :dividend, :nature => :FINAL, value: '0.60'}, {type: :dividend, :nature => :SPECIAL, value: '1.40'}]
      importer.send(:parse_action, 'BONUS 22:1 AND FINAL DIVIDEND RS 0.60 AND SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'}, {type: :dividend, :nature => :FINAL, value: '0.60'}, {type: :dividend, :nature => :SPECIAL, value: '1.40'}]
    end

    it 'should not split if / is immediately after number' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'DIVIDEND-RS.16/ PER SHARE').should == [{type: :dividend, :nature => :DIVIDEND, value: '16'}]
      importer.send(:parse_action, 'AGM/DIVIDEND-RS.5/ PER SH').should == [{type: :ignore, data: 'AGM'}, {type: :dividend, :nature => :DIVIDEND, value: '5'}]
    end

    it 'should ignore debenture, rights' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'BONUS DEBENTURES 1:1').should == [{:type => :ignore, :data => "BONUS DEBENTURES 1:1"}]
      importer.send(:parse_action, 'RGTS-EQ 29:100@PREM RS135').should == [{:type => :ignore, :data => "RGTS-EQ 29:100@PREM RS135"}]
      importer.send(:parse_action, 'RH2:9@PRM215').should == [{:type => :ignore, :data => "RH2:9@PRM215"}]
    end

    it 'should ignore noises' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'ARNGMNT').should == [{:type => :ignore, :data => "ARNGMNT"}]
      importer.send(:parse_action, '-').should == [{:type => :ignore, :data => "-"}]
      importer.send(:parse_action, 'ELEC.').should == [{:type => :ignore, :data => "ELEC."}]
      importer.send(:parse_action, 'WARRANT').should == [{:type => :ignore, :data => "WARRANT"}]
      importer.send(:parse_action, 'WRNT').should == [{:type => :ignore, :data => "WRNT"}]
      importer.send(:parse_action, 'WAR : 5 EQ').should == [{:type => :ignore, :data => "WAR : 5 EQ"}]
      importer.send(:parse_action, 'CAPT.').should == [{:type => :ignore, :data => "CAPT."}]
      importer.send(:parse_action, 'BK CL').should == [{:type => :ignore, :data => "BK CL"}]
      importer.send(:parse_action, 'FCD').should == [{:type => :ignore, :data => "FCD"}]
      importer.send(:parse_action, 'CCPS').should == [{:type => :ignore, :data => "CCPS"}]
      importer.send(:parse_action, 'ANN BC').should == [{:type => :ignore, :data => "ANN BC"}]
      importer.send(:parse_action, 'ANN CLSNG').should == [{:type => :ignore, :data => "ANN CLSNG"}]
    end

    it 'should ignore line separator' do
      importer = Importer::Nse::CorporateActionImporter.new
      importer.send(:parse_action, 'BONUS 2:1\n').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.send(:parse_action, 'BONUS 2:1//RGTS').should == [{type: :bonus, bonus: '2', holding: '1'}, {:type => :ignore, :data => "RGTS"}]
    end

  end

  it 'should import for TCS', ft: true do
    stock = Stock.create!(symbol: 'TCS', nse_series: 'EQ', face_value: 10, nse_active: true)
    Importer::Nse::CorporateActionImporter.new.import
    DividendAction.count.should > 30
    BonusAction.count.should > 0
  end

  def corporate_action_json
    <<EOF
"Symbol","Company","Industry","Series","Face Value(Rs.)","Purpose","Ex-Date","Record Date","BC Start Date","BC End Date","No Delivery Start Date","No Delivery End Date"
"RELIANCE","Reliance Industries Limited","-","EQ","10","ERROR AND DIVIDEND RS.8.50 PER SHARE","31-May-2012","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","ANNUAL GENERAL MEETING AND DIVIDEND 90%","31-May-2011","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","INTERIM DIVIDEND 90% AND FINAL DIVIDEND 100% AND SPECIAL DIVIDEND 120%","31-May-2010","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","INTERIM DIVIDEND 10% AND FINAL DIVIDEND 10%","31-May-2009","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","BONUS 2:3","01-Jun-2008","-","01-Jun-2008","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","FV SPLIT RS.10 TO RS.2","01-Jun-2007","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","ERROR1 AND ERROR2","01-Jun-2004","-","08-Jul-2005","19-Jul-2005","-","-"
"RELIANCE","Reliance Industries Limited","-","EQ","10","CONSOLIDATION RE1 TO RS10","01-Jun-2005","-","08-Jul-2005","19-Jul-2005","-","-"
EOF
  end
end

