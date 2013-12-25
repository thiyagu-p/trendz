require 'mechanize'
require 'logger'
require 'csv'

module Importer
  module Bse
    class StockMaster
      def import
        begin
          agent = Mechanize.new
          csv = fetch_stock_list_csv(agent, fetch_first_page(agent, fetch_landing_page(agent)))
          process_csv(csv.content)
          ImportStatus.completed_upto_today(ImportStatus::Source::BSE_STOCKMASTER)
        rescue => e
          Rails.logger.error "#{e.inspect}"
          ImportStatus.failed(ImportStatus::Source::BSE_STOCKMASTER)
        end
      end

      private
      def process_csv(data)
        CSV.parse(data, {headers: true}) do |row|
          bse_code, bse_symbol, company_name, status_string, bse_group, face_value, isin, industry, instrument = row.fields
          next if isin.nil? or isin.length < 12
          stock = Stock.find_or_create_by_isin(isin)
          stock.update_attributes!(bse_code: bse_code, bse_symbol: bse_symbol,
                                   bse_active: status_string == 'Active',
                                   bse_group: bse_group.strip, industry: industry)
          if stock.symbol.nil?
            stock.update_attributes! symbol: bse_symbol+"_BO", name: company_name, face_value: face_value
          end
        end
      end

      def fetch_stock_list_csv(agent, first_page)
        sleep 10
        form = first_page.form('aspnetForm')
        form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
        form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$lnkDownload'
        form['__EVENTARGUMENT']=''
        begin
          agent.submit(form)
        rescue
          sleep 10
          agent.submit(form)
        end
      end

      def fetch_first_page(agent, landing_page)
        form = landing_page.form('aspnetForm')
        form['ctl00$ContentPlaceHolder1$ddSegment'] = 'Equity'
        form['ctl00$ContentPlaceHolder1$btnSubmit.x'] = 23
        form['ctl00$ContentPlaceHolder1$btnSubmit.y'] = 13
        agent.submit form
      end

      def fetch_landing_page(agent)
        agent.get('http://www.bseindia.com/corporates/List_Scrips.aspx?expandable=1')
      end
    end
  end
end