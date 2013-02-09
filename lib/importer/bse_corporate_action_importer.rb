require 'mechanize'
require 'logger'

#doc = Nokogiri::HTML(open('/Users/thiyagu/Dev/trendz/a.html').read)
#p doc.css('#ctl00_ContentPlaceHolder1_trData').text

def download_corporate_actions
  agent = Mechanize.new
  page = agent.get('http://www.bseindia.com/corporates/corporate_act.aspx')
  form = page.form('aspnetForm')
  form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$lnkDownload'
  form['__EVENTARGUMENT']=''
  form['ctl00$ContentPlaceHolder1$hndvalue'] = 'S'
  form['ctl00$ContentPlaceHolder1$txtDate'] = '01/01/2007'
  form['ctl00$ContentPlaceHolder1$txtTodate'] = '08/02/2013'

  p2 = agent.submit(form)
  pp p2.content
end

def download_stock_list
  agent = Mechanize.new
  agent.log = Logger.new "mech.log"

  page = agent.get('http://www.bseindia.com/corporates/List_Scrips.aspx')
  form = page.form('aspnetForm')
  form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
  form['ctl00$ContentPlaceHolder1$btnSubmit.x'] = 23
  form['ctl00$ContentPlaceHolder1$btnSubmit.y'] = 13
  current_page = agent.submit form
  pp current_page.search("#ctl00_ContentPlaceHolder1_lnkDownload").attribute('href').value
  form = current_page.form('aspnetForm')
  form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
  form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$lnkDownload'
  form['__EVENTARGUMENT']=''
  p2 = agent.submit(form)
  pp p2.content
end

#download_stock_list

def parse_stock_list(actions, tr)
  tds = tr.search('td')
  if tds[0] and tds[0].attribute('class') and tds[0].attribute('class').value =~ /TTRow/
    actions << "#{tds[0].text}, #{tds[1].text}, #{tds[3].text}, #{tds[4].text}, #{tds[5].text}, #{tds[6].text}, #{tds[7].text}"
  end
end

def download_stock_list_pages
  agent = Mechanize.new
  agent.log = Logger.new "mech.log"

  page = agent.get('http://www.bseindia.com/corporates/List_Scrips.aspx')
  form = page.form('aspnetForm')
  form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
  form['ctl00$ContentPlaceHolder1$btnSubmit.x'] = 29
  form['ctl00$ContentPlaceHolder1$btnSubmit.y'] = 19
  current_page = agent.submit form
  current_page.search('#ctl00_ContentPlaceHolder1_gvData tr').each do |tr|
    parse_stock_list(actions, tr)
  end
  page_count_text = current_page.search('#ctl00_ContentPlaceHolder1_trData').text.gsub!(/\r\n/, '')
  p page_count_text
  unless page_count_text =~ /of\s*(\d*)/
    p 'error fetching total pages'
    return
  end
  max_pages = $1.to_i
  (2..max_pages).each do |page_number|
    next_page = "Page$#{page_number}"
    p "#{next_page}"
    form = current_page.form('aspnetForm')
    form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
    form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$gvData'
    form['__EVENTARGUMENT']=next_page
    current_page = agent.submit(form)
    current_page.search('#ctl00_ContentPlaceHolder1_gvData tr').each do |tr|
      parse_stock_list(actions, tr)
    end
  end
  pp actions
end


#agent = Mechanize.new
#actions = []
#agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17'
#page = agent.get('http://www.bseindia.com/corporates/corporate_act.aspx')
#form = page.form('aspnetForm')
#form['ctl00$ContentPlaceHolder1$GetQuote1$txtscrip_code'] = 'Tata Consultancy Services Ltd'
#form['ctl00$ContentPlaceHolder1$hdnCode'] = 532540
#form['ctl00$ContentPlaceHolder1$hndvalue'] = 'S'
#
#form['ctl00$ContentPlaceHolder1$txtDate'] = '01/01/2007'
#form['ddlCalMonthDiv3'] = 1
#form['ddlCalY1earDiv3'] = 2007
#form['ctl00$ContentPlaceHolder1$txtTodate'] = '08/02/2013'
#form['ddlCalMonthDiv4'] = 2
#form['ddlCalYearDiv4'] = 2013
#form['ctl00$ContentPlaceHolder1$btnSubmit.x'] = 25
#form['ctl00$ContentPlaceHolder1$btnSubmit.y'] = 17
#
#p2 = agent.submit(form)
#p2.search('tr.TTRow').each do |tr|
#  tds = tr.search('td')
#  actions << "#{tds[2].text} : #{tds[3].text} : #{tds[4].text}"
#end
#
#p2.search(".pgr").first.search('a').each do |link|
#  if link['href'] =~ /(Page\$\d)/
#    next_page = $1
#    form = p2.form('aspnetForm')
#    form['ctl00$ContentPlaceHolder1$GetQuote1$txtscrip_code'] = 'Tata Consultancy Services Ltd'
#    form['ctl00$ContentPlaceHolder1$hdnCode'] = 532540
#    form['ctl00$ContentPlaceHolder1$hndvalue'] = 'S'
#
#    form['ctl00$ContentPlaceHolder1$txtDate'] = '01/01/2007'
#    form['ctl00$ContentPlaceHolder1$txtTodate'] = '08/02/2013'
#    form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$gvData'
#    form['__EVENTARGUMENT']=next_page
#    p3 = agent.submit(form)
#    p3.search('tr.TTRow').each do |tr|
#      tds = tr.search('td')
#      actions << "#{tds[2].text} : #{tds[3].text} : #{tds[4].text}"
#    end
#  end
#end
#
#pp actions
#agent = Mechanize.new
#agent.log = Logger.new "mech.log"
#agent.user_agent_alias = 'Mac Safari'
#
##agent.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17'
#page = agent.get('http://www.bseindia.com/corporates/ScripWiseCorpAction.aspx?scrip_cd=500710')
#form = page.form('aspnetForm')
#form['ctl00$ContentPlaceHolder1$GetQuote1$txtscrip_code'] = 'Tata Consultancy Services Ltd'
#form['ctl00$ContentPlaceHolder1$hdnCode'] = 532540
#form['ctl00$ContentPlaceHolder1$ddlYear'] = 2011
#form['ctl00$ContentPlaceHolder1$btnSubmit.x'] = 56
#form['ctl00$ContentPlaceHolder1$btnSubmit.y'] = 8

#p2 = agent.submit(form)
#pp p2.body