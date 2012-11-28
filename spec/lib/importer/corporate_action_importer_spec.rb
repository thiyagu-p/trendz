require "spec_helper"

describe Importer::CorporateActionImporter do

  describe :import do
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
      @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=M%26M", Importer::NseConnection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      Importer::CorporateActionImporter.new.import
    end

    it "should import and save parsed data" do
      stock1 = Stock.create(symbol: 'RELIANCE', series: Stock::Series::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock1.symbol}", Importer::NseConnection.user_agent).returns(stub(body: corporate_action_html))
      Importer::CorporateActionImporter.new.import
      corporate_action = CorporateAction.find_by_stock_id stock1.id
      corporate_action.ex_date.should == Date.parse('31/05/2012')
      corporate_action.raw_data.should == 'ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE'
      corporate_action.parsed_data.should == '[{"type":"ignore","data":"ANNUAL GENERAL MEETING"},{"type":"divident","value":"8.50"}]'
    end

    it "should ignore non equity actions" do
      stock1 = Stock.create(symbol: 'RELIANCE', series: Stock::Series::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock1.symbol}", Importer::NseConnection.user_agent).returns(stub(body: corporate_action_html))
      Importer::CorporateActionImporter.new.import
      CorporateAction.count.should == 2
    end

    it "should ignore existing equity actions" do
      stock1 = Stock.create(symbol: 'RELIANCE', series: Stock::Series::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock1.symbol}", Importer::NseConnection.user_agent).returns(stub(body: corporate_action_html))
      @http.expects(:request_get).with("/marketinfo/companyinfo/eod/action.jsp?symbol=#{stock1.symbol}", Importer::NseConnection.user_agent).returns(stub(body: corporate_action_html))
      Importer::CorporateActionImporter.new.import
      CorporateAction.count.should == 2
      Importer::CorporateActionImporter.new.import
      CorporateAction.count.should == 2
    end
  end

  describe :ex_date do
    it 'should use ex_date if exist' do
      doc = Nokogiri::HTML('<tr> <td class=t2>EQ</td> <td class=t2>-</td> <td class=t2>02/06/2012</td> <td class=t2>07/06/2012</td> <td class=t2>31/05/2012</td> <td class=t2>-</td> <td class=t2>-</td> <td class=t0>ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE</td> </tr>')
      Importer::CorporateActionImporter.new.find_ex_date(doc.css('td')).should == Date.parse('31/05/2012')
    end

    it 'should use record_date if ex_date missing' do
      doc = Nokogiri::HTML('<tr> <td class=t2>EQ</td> <td class=t2>02/06/2012</td> <td class=t2>01/06/2012</td> <td class=t2>07/06/2012</td> <td class=t2>-</td> <td class=t2>-</td> <td class=t2>-</td> <td class=t0>ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE</td> </tr>')
      Importer::CorporateActionImporter.new.find_ex_date(doc.css('td')).should == Date.parse('01/06/2012')
    end

    it 'should use BC Start date if exdate and record date missing' do
      doc = Nokogiri::HTML('<tr> <td class=t2>EQ</td> <td class=t2>-</td> <td class=t2>02/06/2012</td> <td class=t2>07/06/2012</td> <td class=t2>-</td> <td class=t2>-</td> <td class=t2>-</td> <td class=t0>ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE</td> </tr>')
      Importer::CorporateActionImporter.new.find_ex_date(doc.css('td')).should == Date.parse('01/06/2012')
    end
  end
  describe :parse_action do
    it 'should parse value divident' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('DIVIDEND RS 1.80 PER SHARE').first.should == {type: :divident, value: '1.80'}
      importer.parse_action('DIVIDEND RS1.80 PER SHARE').first.should == {type: :divident, value: '1.80'}
      importer.parse_action('DIVIDEND RS 10 PER SHARE').first.should == {type: :divident, value: '10'}
      importer.parse_action('DIVIDEND RS10 PER SHARE').first.should == {type: :divident, value: '10'}
      importer.parse_action('DIVIDEND RS.10 PER SHARE').first.should == {type: :divident, value: '10'}
      importer.parse_action('DIVIDEND RS.4.50 PER SHARE').first.should == {type: :divident, value: '4.50'}
      importer.parse_action('DIVIDEND-RE.0.20 PER SHARE').first.should == {type: :divident, value: '0.20'}
      importer.parse_action('DV-RE.1 PR SH').first.should == {type: :divident, value: '1'}
    end
    it 'should ignore nil divident' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('DIVIDEND-NIL').first.should == {type: :ignore, data: 'DIVIDEND-NIL'}
    end
    it 'should parse percentage divident' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('DIVIDEND-120%').first.should == {type: :divident, percentage: '120'}
      importer.parse_action('DIVIDEND - 17.50%').first.should == {type: :divident, percentage: '17.50'}
    end
    it 'should parse combined value dividents' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('DIV-FIN RS.1.5+INT RS.2.1PURPOSE REVISED').should == [{type: :divident, value: '1.5'},{type: :divident, value: '2.1'}]
      importer.parse_action('DIVIDEND - FINAL RS 22 + SPECIAL RS 10').should == [{type: :divident, value: '22'},{type: :divident, value: '10'}]
      importer.parse_action('DIV-FIN RE0.25+SPL RE0.35').should == [{type: :divident, value: '0.25'},{type: :divident, value: '0.35'}]
      importer.parse_action('DIV-RS10+GLD JUB-RS12.1').should == [{type: :divident, value: '10'},{type: :divident, value: '12.1'}]
    end
    it 'should parse combined percentage dividents' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('DIV-50% + SPL DIV-60%').should == [{type: :divident, percentage: '50'},{type: :divident, percentage: '60'}]
      importer.parse_action('DIV.-FIN.75%+SPL.25%').should == [{type: :divident, percentage: '75'},{type: :divident, percentage: '25'}]
      importer.parse_action('DIV-(FIN-100%+SP-30%)').should == [{type: :divident, percentage: '100'},{type: :divident, percentage: '30'}]
      importer.parse_action('FINALDIV.-10%+SPL.DIV.-5%').should == [{type: :divident, percentage: '10'},{type: :divident, percentage: '5'}]
    end

    it 'should parse split' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('FV SPLIT RS.10/- TO RS.1/').should == [{type: :split, from: '10', to: '1'}]
      importer.parse_action('FV SPLIT RS 10 TO RS 1').should == [{type: :split, from: '10', to: '1'}]
      importer.parse_action('FV SPLIT RS.10 TO RS.5').should == [{type: :split, from: '10', to: '5'}]
      importer.parse_action('SPL RS10-RS2').should == [{type: :split, from: '10', to: '2'}]
    end

    it 'should parse consolidation' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('CONSOLIDATION RE1 TO RS10').should == [{type: :consolidation, from: '1', to: '10'}]
      importer.parse_action('CONSOLIDATION RE.1/- TO RS.10/-').should == [{type: :consolidation, from: '1', to: '10'}]
    end

    it 'should parse bonus' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('BONUS 2:1').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.parse_action('BON-2:1').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.parse_action('BONUS28:100').should == [{type: :bonus, bonus: '28', holding: '100'}]
    end

    it 'should handle multiple actions split by AND' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('BONUS 22:1 AND FACE VALUE SPLIT FROM RS.10/- TO RE.1/').should ==
          [{type: :bonus, bonus: '22', holding: '1'},{type: :split, from: '10', to: '1'}]
      importer.parse_action('DIVIDEND RS.6/- PER SHARE AND FACE VALUE SPLIT FROM RS.2/- TO RE.1/-').should ==
          [{type: :divident, value: '6'},{type: :split, from: '2', to: '1'}]
      importer.parse_action('BONUS - 1:1 AND FACE VALUE SPLIT FROM RS. 10 TO RS. 2').should ==
          [{type: :bonus, bonus: '1', holding: '1'},{type: :split, from: '10', to: '2'}]
      importer.parse_action('BONUS 1:2 AND FACE VALUE SPLIT FROM RS.10 TO RS.2').should ==
          [{type: :bonus, bonus: '1', holding: '2'},{type: :split, from: '10', to: '2'}]
      importer.parse_action('INTERIM DIVIDEND RS.3/- PER SHARE AND FACE VALUE SPLIT FROM RS.5/- TO RS.2/- (PURPOSE REVISED)').should ==
          [{type: :divident, value: '3'},{type: :split, from: '5', to: '2'}]
    end

    it 'should handle multiple actions split by / and AND' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('BONUS 22:1 / FINAL DIVIDEND RS 0.60  AND SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'},{type: :divident, value: '0.60'},{type: :divident, value: '1.40'}]
      importer.parse_action('BONUS 22:1 AND FINAL DIVIDEND RS 0.60  + SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'},{type: :divident, value: '0.60'},{type: :divident, value: '1.40'}]
      importer.parse_action('BONUS 22:1 AND FINAL DIVIDEND RS 0.60 AND SPECIAL DIVIDEND RS 1.40 PER SHARE.').should ==
          [{type: :bonus, bonus: '22', holding: '1'},{type: :divident, value: '0.60'},{type: :divident, value: '1.40'}]
    end

    it 'should ignore debenture, rights' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('BONUS DEBENTURES 1:1').should == [{:type=>:ignore, :data=>"BONUS DEBENTURES 1:1"}]
      importer.parse_action('RGTS-EQ 29:100@PREM RS135').should == [{:type=>:ignore, :data=>"RGTS-EQ 29:100@PREM RS135"}]
      importer.parse_action('RH2:9@PRM215').should == [{:type=>:ignore, :data=>"RH2:9@PRM215"}]
    end

    it 'should ignore noises' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('ARNGMNT').should == [{:type=>:ignore, :data=>"ARNGMNT"}]
      importer.parse_action('-').should == [{:type=>:ignore, :data=>"-"}]
      importer.parse_action('ELEC.').should == [{:type=>:ignore, :data=>"ELEC."}]
      importer.parse_action('WARRANT').should == [{:type=>:ignore, :data=>"WARRANT"}]
      importer.parse_action('WRNT').should == [{:type=>:ignore, :data=>"WRNT"}]
      importer.parse_action('WAR : 5 EQ').should == [{:type=>:ignore, :data=>"WAR : 5 EQ"}]
      importer.parse_action('CAPT.').should == [{:type=>:ignore, :data=>"CAPT."}]
      importer.parse_action('BK CL').should == [{:type=>:ignore, :data=>"BK CL"}]
      importer.parse_action('FCD').should == [{:type=>:ignore, :data=>"FCD"}]
      importer.parse_action('CCPS').should == [{:type=>:ignore, :data=>"CCPS"}]
    end

    it 'should ignore line separator' do
      importer = Importer::CorporateActionImporter.new
      importer.parse_action('BONUS 2:1\n').should == [{type: :bonus, bonus: '2', holding: '1'}]
      importer.parse_action('BONUS 2:1//RGTS').should == [{type: :bonus, bonus: '2', holding: '1'},{:type=>:ignore, :data=>"RGTS"}]
    end

  end
end

def corporate_action_html
<<EOF
<HTML>
<BODY bgcolor="#ffffff" leftmargin=0 topmargin=0 marginheight=0 marginwidth=0>
<div name="menulayer" id="menulayer" class=menufont style="background-color: #f5c078; visibility:hidden; position:absolute; width:1px; height:1px; z-index:1; left:1; top:1"></div>
<TABLE cellspacing=0 border=0 cellpadding=0 height=100%>
<tr>
<td width=600 valign=top>
<TABLE CELLPADDING=0 CELLSPACING=0 BORDER=0 width=592 height=100%>
<TR>
<TD width=20>&nbsp;</TD>
<TD valign=top>
<font class=header>Corporate Information</font><br>
<font class=header3>Corporate Actions</font><br><br>
	<table border=0 cellspacing=1 cellpadding=4 align=center width=450>
	<tr>
	<td class=tablehead WIDTH=100>Company</td>
	<td class=t0>Reliance Industries Limited</td>
	</tr>
	<tr>
	<td class=tablehead WIDTH=100>NSE Symbol</td>
	<td class=t0><a href="/marketinfo/equities/quotesearch.jsp?companyname=RELIANCE">RELIANCE</a></td>
	</tr>
	</table><br>
	<table border="0">
		 <tr><td>
	<table cellpadding=0 cellspacing=0 border=0 align=center bgcolor=#969696>
	<tr><td>
 <table cellpadding=2 border=0 cellspacing=1 align=center width=570>
 <TR>
	<TD class=tablehead>Series</TD>
	<TD class=tablehead>Record Date</TD>
	<TD class=tablehead>BC Start Date</TD>
	<TD class=tablehead>BC End Date</TD>
	<TD class=tablehead>Ex Date</TD>
	<TD class=tablehead>No Delivery Start Date</TD>
	<TD class=tablehead>No Delivery End Date</TD>
	<TD class=tablehead>Purpose</TD>
	</tr>
	<tr>
	 <td class=t2>BL</td>
	 <td class=t2>-</td>
	 <td class=t2>03/06/2006</td>
	 <td class=t2>10/06/2006</td>
	 <td class=t2>01/06/2006</td>
	 <td class=t2>-</td>
	 <td class=t2>-</td>
	<td class=t0>DIVIDEND-RS.10/- PER SH</td>
	</tr>
	<tr>
	 <td class=t2>EQ</td>
	 <td class=t2>-</td>
	 <td class=t2>02/06/2012</td>
	 <td class=t2>07/06/2012</td>
	 <td class=t2>31/05/2012</td>
	 <td class=t2>-</td>
	 <td class=t2>-</td>
	<td class=t0>ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE</td>
	</tr>
	<tr>
	 <td class=t2>EQ</td>
	 <td class=t2>-</td>
	 <td class=t2>02/06/2011</td>
	 <td class=t2>07/06/2011</td>
	 <td class=t2>31/05/2011</td>
	 <td class=t2>-</td>
	 <td class=t2>-</td>
	<td class=t0>ANNUAL GENERAL MEETING AND DIVIDEND RS.8.50 PER SHARE</td>
	</tr>
 </table></td></tr></table>
	</td></tr>
 </table>
</td>
<td width=10></td>
</tr>
</table>
</td>
</tr>
</table>
</body>
</html>
EOF
end