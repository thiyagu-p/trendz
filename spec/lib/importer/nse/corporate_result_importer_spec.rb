require "spec_helper"

describe Importer::Nse::CorporateResultImporter do

  describe :import do
    it "should encode symbol" do
      stock = Stock.create(symbol: 'M&M', nse_series: Stock::NseSeries::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/corporates/corpInfo/equities/resHistory.jsp?symbol=M%26M", Importer::Nse::Connection.user_agent).returns(stub(:class => Net::HTTPNotFound))
      Importer::Nse::CorporateResultImporter.new.fetch_data_for stock
    end

    it "should import and save parsed data" do
      stock1 = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/corporates/corpInfo/equities/resHistory.jsp?symbol=#{stock1.symbol}", Importer::Nse::Connection.user_agent).returns(stub(body: result_history_html))
      Importer::Nse::CorporateResultImporter.new.fetch_data_for stock1
      corporate_result = CorporateResult.find_by_stock_id_and_quarter_end stock1.id, '2012-09-30'
      corporate_result.net_sales.should == 9033500.00
      corporate_result.net_p_and_l.should == 537600.00
      corporate_result.eps_before_extraordinary.should == 16.6
      corporate_result.eps.should == 16.6
    end

    it "should import and save parsed data for all quarters" do
      stock1 = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/corporates/corpInfo/equities/resHistory.jsp?symbol=#{stock1.symbol}", Importer::Nse::Connection.user_agent).returns(stub(body: result_history_html))
      Importer::Nse::CorporateResultImporter.new.fetch_data_for stock1
      corporate_results = CorporateResult.order(:quarter_end).to_a
      corporate_results.collect(&:quarter_end).should == [Date.parse('30/09/2011'),Date.parse('31/12/2011'),Date.parse('31/03/2012'),Date.parse('30/06/2012'),Date.parse('30/09/2012')]
    end

    it "should ignore existing equity actions" do
      stock1 = Stock.create(symbol: 'RELIANCE', nse_series: Stock::NseSeries::EQUITY)
      @http = stub()
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      Net::HTTP.expects(:new).with(NSE_URL).returns(@http)
      @http.expects(:request_get).with("/corporates/corpInfo/equities/resHistory.jsp?symbol=#{stock1.symbol}", Importer::Nse::Connection.user_agent).returns(stub(body: result_history_html))
      @http.expects(:request_get).with("/corporates/corpInfo/equities/resHistory.jsp?symbol=#{stock1.symbol}", Importer::Nse::Connection.user_agent).returns(stub(body: result_history_html))
      Importer::Nse::CorporateResultImporter.new.fetch_data_for stock1
      CorporateResult.count.should == 5
      Importer::Nse::CorporateResultImporter.new.fetch_data_for stock1
      CorporateResult.count.should == 5
    end
  end

end

def result_history_html
<<EOF




<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
<HEAD>
<TITLE>NSE - Corporates - History of Financial Results</TITLE>
<!--<LINK href="/nse.css" rel=STYLESHEET type=text/css>-->
<meta http-equiv="X-UA-Compatible" content="IE=Edge">
<LINK href="/corporates/resources/css/nse_corp.css" rel=STYLESHEET type=text/css>
<style>
.highlightedRow{
	background-color:#ffebcc;
}
.specialhead3{
	background-color:#F5F0D9;
}
</style>
<script language="javascript" src="/js/commonfuncs.js"></script>
</HEAD>

<script language="javascript">
function popup1 ( url ) {
        //alert(url);
        window.open( url,'Remark','location=no,menubar=no,toolbar=no,resizable=no,scrollbars=yes,status=yes,width=600,height=140,screenX=0,screenY=0,left=0,top=240');}
</script>

<BODY  >
<!--
<table style="background-color: white;border-top: 1px solid white;border-right: 1px solid white;border-bottom: 1px solid white;border-left: 1px solid white;"><tr><td height=10></td></tr></table>
-->
<TABLE width=592 height=100% >







<!--
<table border=0 cellspacing=1 cellpadding=4 align=center width=400 class=viewTable>
<tr>
<td class=tablehead width=100>Company</td>
<td class=t1>Reliance Industries Limited</td>
</tr>
<tr>
<td class=tablehead width=100>NSE Symbol</td>
<td class=t1><a href="/marketinfo/equities/quotesearch.jsp?companyname=RELIANCE">RELIANCE</a></td>
</tr>
</table>
<br>
-->

<TABLE>
<td width=1000>
<TABLE cellpadding=0 cellspacing=0 border=0 align=center bgcolor=#ffffff>
<tr>
<td align=right colspan=6 border=0 bgcolor=#ffffff class=smalllinks>&nbsp; &nbsp;(All figures in Rs. Lakhs)</td>
</tr>
<tr><td>
<table cellpadding=4 border=0 cellspacing=1 align=center  class=viewTable>

<tr>

<td class=tablehead style="width:290px" align = center><font size=2px face=arial ><b>Quarter Ended</b></font></td><td class=tablehead style="width:110px" bgcolor=#CC3300 align = center><font size=2px face=arial color=#ffffff><b> 30-SEP-2012</b></font></td><td class=tablehead style="width:110px" bgcolor=#CC3300 align = center><font size=2px face=arial color=#ffffff><b> 30-JUN-2012</b></font></td><td class=tablehead style="width:110px" bgcolor=#CC3300 align = center><font size=2px face=arial color=#ffffff><b> 31-MAR-2012</b></font></td><td class=tablehead style="width:110px" bgcolor=#CC3300 align = center><font size=2px face=arial color=#ffffff><b> 31-DEC-2011</b></font></td><td class=tablehead style="width:110px" bgcolor=#CC3300 align = center><font size=2px face=arial color=#ffffff><b> 30-SEP-2011</b></font></td>
</tr>
<tr>
<td class=tablehead style="width:290px" align = center><font size=2pt face=arial ><b>Particulars</b></font></td>
<!-- <td class=tablehead>Particulars</td> width=310-->
        <td class=tablehead style="width:110px" align = center><font size=1pt face=arial ><b>Unaudited<br><br></b></font></td>
<td class=tablehead style="width:110px" align = center><font size=1pt face=arial ><b>Unaudited<br><br></b></font></td>
<td class=tablehead style="width:110px" align = center><font size=1pt face=arial ><b>Audited<br><br></b></font></td>
<td class=tablehead style="width:110px" align = center><font size=1pt face=arial ><b>Unaudited<br><br></b></font></td>
<td class=tablehead style="width:110px" align = center><font size=1pt face=arial ><b>Unaudited<br><br></b></font></td>

</tr>
</table>
</TABLE>

<!-- </frame>
<frame name="h2" scrolling="YES" noresize> -->
<div style="overflow: auto; width: 1000px; height: 240px;padding-left:18px;">

<table cellpadding=4 cellspacing=1 align=center class=viewTable >
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Net Sales/Income from Operations</b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>9033500.00</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >9187500.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >8518200.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >8513500.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >7856900.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Other Operating Income</td>
<td class=t1 style="width:110px;text-align:right;"><b>-</b></td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Other Income<sup>1</sup></td>
<td class=t1 style="width:110px;text-align:right;"><b>-</b></td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Total Income<sup>2</sup></td>
<td class=t1 style="width:110px;text-align:right;"><b>9033500.00</b></td>
<td class=t1 style="width:110px;text-align:right;">9187500.00</td>
<td class=t1 style="width:110px;text-align:right;">8518200.00</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Changes in inventories of finished goods, work-in-progress and stock-in-trade</td>
<td class=t1 style="width:110px;text-align:right;"><b>-178400.00</b></td>
<td class=t1 style="width:110px;text-align:right;">-98700.00</td>
<td class=t1 style="width:110px;text-align:right;">132700.00</td>
<td class=t1 style="width:110px;text-align:right;">-148900.00</td>
<td class=t1 style="width:110px;text-align:right;">-160700.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Cost of materials consumed</td>
<td class=t1 style="width:110px;text-align:right;"><b>7779600.00</b></td>
<td class=t1 style="width:110px;text-align:right;">7933500.00</td>
<td class=t1 style="width:110px;text-align:right;">7151900.00</td>
<td class=t1 style="width:110px;text-align:right;">7419000.00</td>
<td class=t1 style="width:110px;text-align:right;">6466100.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Purchases of stock-in-trade</td>
<td class=t1 style="width:110px;text-align:right;"><b>5400.00</b></td>
<td class=t1 style="width:110px;text-align:right;">16300.00</td>
<td class=t1 style="width:110px;text-align:right;">24200.00</td>
<td class=t1 style="width:110px;text-align:right;">11200.00</td>
<td class=t1 style="width:110px;text-align:right;">51400.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Employee benefits expense</td>
<td class=t1 style="width:110px;text-align:right;"><b>84400.00</b></td>
<td class=t1 style="width:110px;text-align:right;">84700.00</td>
<td class=t1 style="width:110px;text-align:right;">59700.00</td>
<td class=t1 style="width:110px;text-align:right;">67200.00</td>
<td class=t1 style="width:110px;text-align:right;">71500.00</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Depreciation and amortisation expense</b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>227700.00</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >243400.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >265900.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >257000.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >296900.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Total Expenditure Excluding Other Expenditures </td>
<td class=t1 style="width:110px;text-align:right;"><b>7918700.00</b></td>
<td class=t1 style="width:110px;text-align:right;">8179200.00</td>
<td class=t1 style="width:110px;text-align:right;">7634400.00</td>
<td class=t1 style="width:110px;text-align:right;">7605500.00</td>
<td class=t1 style="width:110px;text-align:right;">6725200.00</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Other expenses</b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>572000.00</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >577000.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >493400.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >436500.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >444200.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Total expenses</td>
<td class=t1 style="width:110px;text-align:right;"><b>8490700.00</b></td>
<td class=t1 style="width:110px;text-align:right;">8756200.00</td>
<td class=t1 style="width:110px;text-align:right;">8127800.00</td>
<td class=t1 style="width:110px;text-align:right;">8042000.00</td>
<td class=t1 style="width:110px;text-align:right;">7169400.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  > Interest<sup>3</sup></td>
<td class=t1 style="width:110px;text-align:right;"><b>-</b></td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
<td class=t1 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Exceptional Items <sup>4</sup></b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>-</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Profit / (Loss) from operations before other income, finance costs and exceptional items</td>
<td class=t1 style="width:110px;text-align:right;"><b>542800.00</b></td>
<td class=t1 style="width:110px;text-align:right;">431300.00</td>
<td class=t1 style="width:110px;text-align:right;">390400.00</td>
<td class=t1 style="width:110px;text-align:right;">471500.00</td>
<td class=t1 style="width:110px;text-align:right;">687500.00</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Other Income<sup>5</sup></b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>211200.00</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >190400.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >229500.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >171700.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >110200.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Profit / (Loss) from ordinary activities before finance costs and exceptional items</td>
<td class=t1 style="width:110px;text-align:right;"><b>754000.00</b></td>
<td class=t1 style="width:110px;text-align:right;">621700.00</td>
<td class=t1 style="width:110px;text-align:right;">619900.00</td>
<td class=t1 style="width:110px;text-align:right;">643200.00</td>
<td class=t1 style="width:110px;text-align:right;">797700.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Finance costs<sup>6</sup></td>
<td class=t1 style="width:110px;text-align:right;"><b>73700.00</b></td>
<td class=t1 style="width:110px;text-align:right;">78400.00</td>
<td class=t1 style="width:110px;text-align:right;">76800.00</td>
<td class=t1 style="width:110px;text-align:right;">69400.00</td>
<td class=t1 style="width:110px;text-align:right;">66000.00</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Profit / (Loss) from ordinary activities after finance costs but before exceptional items</td>
<td class=t1 style="width:110px;text-align:right;"><b>680300.00</b></td>
<td class=t1 style="width:110px;text-align:right;">543300.00</td>
<td class=t1 style="width:110px;text-align:right;">543100.00</td>
<td class=t1 style="width:110px;text-align:right;">573800.00</td>
<td class=t1 style="width:110px;text-align:right;">731700.00</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Exceptional Items<sup>7</sup></b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>-</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
<td class=highlightedRow style="width:110px;text-align:right;" >-</td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;"  >Profit (+)/ Loss (-) from Ordinary Activities before tax</td>
<td class=t1 style="width:110px;text-align:right;"><b>680300.00</b></td>
<td class=t1 style="width:110px;text-align:right;">543300.00</td>
<td class=t1 style="width:110px;text-align:right;">543100.00</td>
<td class=t1 style="width:110px;text-align:right;">573800.00</td>
<td class=t1 style="width:110px;text-align:right;">731700.00</td>
</tr>
<tr><td class=highlightedRow style="width:290px;text-align:left;"><b>Tax expense</b></td>
<td class=highlightedRow style="width:110px;text-align:right"  ><b>142700.00</b></td>
<td class=highlightedRow style="width:110px;text-align:right;" >96000.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >119500.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >129800.00</td>
<td class=highlightedRow style="width:110px;text-align:right;" >161400.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" > Net Profit (+)/Loss(-) from Ordinary Activities after tax </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>537600.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">447300.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">423600.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">444000.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">570300.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Extraordinary Items</td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" > Net Profit (_)/Loss(-) for the period </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>537600.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">447300.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">423600.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">444000.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">570300.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Dividend (%) </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" > Face Value (In Rs</td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>10.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">10.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">10.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">10.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">10.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Paid Up Equity Share Capital </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>323600.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">324200.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">327100.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">327500.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">327400.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Reserves Excluding Revaluation Reserve </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
<td class=specialhead3 style="width:110px;text-align:right;">-</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Basic EPS after Extraordinary items (As Furnished) </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>16.60</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">13.70</td>
<td class=specialhead3 style="width:110px;text-align:right;">12.90</td>
<td class=specialhead3 style="width:110px;text-align:right;">13.60</td>
<td class=specialhead3 style="width:110px;text-align:right;">17.40</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Diluted EPS after Extraordinary items (As Furnished) </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>16.6</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">13.7</td>
<td class=specialhead3 style="width:110px;text-align:right;">12.9</td>
<td class=specialhead3 style="width:110px;text-align:right;">13.6</td>
<td class=specialhead3 style="width:110px;text-align:right;">17.4</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Basic EPS before Extraordinary items (As Furnished) </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>16.60</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">13.70</td>
<td class=specialhead3 style="width:110px;text-align:right;">12.90</td>
<td class=specialhead3 style="width:110px;text-align:right;">13.60</td>
<td class=specialhead3 style="width:110px;text-align:right;">17.40</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Diluted EPS before Extraordinary items (As Furnished) </td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>16.6</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">13.7</td>
<td class=specialhead3 style="width:110px;text-align:right;">12.9</td>
<td class=specialhead3 style="width:110px;text-align:right;">13.6</td>
<td class=specialhead3 style="width:110px;text-align:right;">17.4</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Public Shareholding (No. of Shares)</td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>1771700000.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">1778600000.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">1807100000.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">1810700000.00</td>
<td class=specialhead3 style="width:110px;text-align:right;">1810500000.00</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Public Shareholding (%)</td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>54.75</b></td>
<td class=specialhead3 style="width:110px;text-align:right;">54.85</td>
<td class=specialhead3 style="width:110px;text-align:right;">55.25</td>
<td class=specialhead3 style="width:110px;text-align:right;">55.29</td>
<td class=specialhead3 style="width:110px;text-align:right;">55.29</td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Number of Shares  Pledged / Encumbered</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>0.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>0.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>0.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>0.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>0.00</b></td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Shares  Pledged / Encumbered (as a %  of total shareholding of Promoter and Promoter Group)</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Shares  Pledged / Encumbered (as a %  total share capital of the company)</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>-</b></td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Number of Shares  Non-encumbered</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>1463900000.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>1463900000.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>1463900000.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>1463900000.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>1463900000.00</b></td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Shares  Non-encumbered (as a %  of total shareholding of Promoter and Promoter Group)</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>100.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>100.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>100.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>100.00</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>100.00</b></td>
</tr>
<tr><td class=specialhead3 style="width:290px;text-align:left;" >Promoter & Promoter group Shares  Non-encumbered (as a %  total share capital of the company)</td>
<td class=specialhead3 style="width:110px;text-align:right;"  ><b>45.25</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>45.15</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>44.75</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>44.71</b></td>
<td class=specialhead3 style="width:110px;text-align:right;"><b>44.71</b></td>
</tr>
<tr><td class=t0 style="width:290px;text-align:left;" ></td>
<td class=t0 style="width:110px;text-align:right;" >-</td>
<td class=t0 style="width:110px;text-align:right;" >-</td>
<td class=t0 style="width:110px;text-align:right;" >-</td>
<td class=t0 style="width:110px;text-align:right;" >-</td>
<td class=t0 style="width:110px;text-align:right;" >-</td>
</tr>

</TABLE>
</table>
</div>

<br>
        <p class=smalllinks align="left" style="margin-left:50px">
           <b>Note </b> : <br>

		  <sup>1</sup> Other Income pertains to periods ending on or before August 31, 2008
                   <br><sup>2</sup> Total Income pertains to periods ending on or before August 31, 2008
                   <br><sup>3</sup> Interest  pertains to periods ending on or before August 31, 2008
			     <BR>
		    <sup>4</sup>  Exceptional Items  pertains to periods ending on or before August 31, 2008.<BR>
			<sup>5</sup>   Other Income pertains to periods ending after August 31, 2008<BR>
			<sup>6</sup>  Finance Costs pertains to periods ending after August 31, 2008 <BR>
			<sup>7</sup> Exceptional Items pertains to periods ending after August 31, 2008
			<br>

        </p>
<br>
<br>

</td></tr>
</table>

</BODY>
</HTML>
EOF
end