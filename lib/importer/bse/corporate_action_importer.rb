require 'mechanize'
require 'csv'

module Importer
  module Bse
    class CorporateActionImporter
      include Importer::CorporateActionParser

      DATE_FORMAT = "%d/%m/%Y"

      def import
        begin
          parse_and_save_data(download_corporate_actions)
          ImportStatus.completed_upto_today ImportStatus::Source::BSE_CORPORATE_ACTION
        rescue => e
          Rails.logger.error e.inspect
          ImportStatus.failed ImportStatus::Source::BSE_CORPORATE_ACTION
        end

      end

      def download_corporate_actions
        status = ImportStatus.find_by(source: ImportStatus::Source::BSE_CORPORATE_ACTION)

        agent = Mechanize.new
        page = agent.get('http://www.bseindia.com/corporates/corporate_act.aspx')
        form = page.form('aspnetForm')
        form['__EVENTTARGET']='ctl00$ContentPlaceHolder1$lnkDownload'
        form['__EVENTARGUMENT']=''
        form['ctl00$ContentPlaceHolder1$hndvalue'] = 'S'
        form['ctl00$ContentPlaceHolder1$txtDate'] = (status.data_upto - 1).strftime(DATE_FORMAT)
        form['ctl00$ContentPlaceHolder1$txtTodate'] = (Date.today + 90).strftime(DATE_FORMAT)
        p2 = agent.submit(form)
        p2.content
      end

      def parse_and_save_data data
        CSV.parse(data, {headers: true}) do |row|
          bse_code, stock_name, ex_date, purpose, record_date, bc_start_date, bc_end_date, nd_start_date, nd_end_date = row.fields
          stock = Stock.find_by(bse_code: bse_code)
          if stock && ex_date
            action = parse_action(purpose)
            persist_actions(purpose, parse_action(purpose), Date.parse(ex_date), stock)
          end
        end
      end

      def parse_action(action)
        data = nil
        if action =~ /DIVIDEND/i
          data = parse_dividend(action)
        elsif action =~ /SPLIT/i
          data = parse_split(action)
        elsif action =~ /BONUS/i && !(action =~ /DEBENTURES/i)
          data = parse_bonus(action)
        elsif action =~ /CONSOLIDATION/i
          data = parse_consolidation(action)
        elsif action =~ /RIGHT|REDUCTION|AMALGA|BUY\sBACK|ARRANGEMENT/i
          data = {type: :ignore, data: action}
        else
          data = {type: :unknown, data: action}
        end
        return [data]
      end

    end
  end
end
