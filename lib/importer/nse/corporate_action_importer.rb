require 'csv'

module Importer
  module Nse
    class CorporateActionImporter
      include Connection
      include Importer::CorporateActionParser

      def self.more_than_24_months_url symbol
        "/corporates/datafiles/CA_#{CGI.escape(symbol)}_MORE_THAN_24_MONTHS.csv"
      end

      FORTHCOMING_URL = "/corporates/corpInfo/equities/getCorpActions.jsp?symbol=&Industry=&ExDt=All%20Forthcoming&exDt=All%20Forthcoming&recordDt=&bcstartDt=&industry=&CAType="

      LAST_15_DAYS = "/corporates/corpInfo/equities/getCorpActions.jsp?symbol=&Industry=&ExDt=Last%2015%20Days&exDt=Last%2015%20Days&recordDt=&bcstartDt=&industry=&CAType="
      LAST_3_MONTHS = '/corporates/corpInfo/equities/getCorpActions.jsp?symbol=&Industry=&ExDt=Last%203%20Months&exDt=Last%203%20Months&recordDt=&bcstartDt=&industry=&CAType='

      def import

        begin
          status =  ImportStatus.find_by(source: ImportStatus::Source::NSE_CORPORATE_ACTION)

          days_since_last_run = status.data_upto.nil? ? 1000 : Date.today - status.data_upto
          case days_since_last_run
            when 0..14 then fetch_last_15_days
            when 15..89 then fetch_last_3_months
            else fetch_complete_history
          end
          fetch_future
          ImportStatus.completed_upto_today ImportStatus::Source::NSE_CORPORATE_ACTION
        rescue => e
          p "Nse::CorporateActionImporter Failed - #{e.backtrace}"
          ImportStatus.failed ImportStatus::Source::NSE_CORPORATE_ACTION
        end

      end

      private

      def fetch_last_3_months
        download_data_from(CorporateActionImporter::LAST_3_MONTHS)
      end

      def fetch_last_15_days
        download_data_from(CorporateActionImporter::LAST_15_DAYS)
      end

      def fetch_future
        download_data_from(CorporateActionImporter::FORTHCOMING_URL)
      end

      def fetch_complete_history
        Stock.all(order: :symbol, conditions: "nse_active").each do |stock|
          begin
            download_data_from(CorporateActionImporter.more_than_24_months_url stock.symbol)
          rescue => e
            p "Error importing company info for #{stock.symbol} #{e.inspect}"
          end
        end
      end

      def download_data_from(url)
        response = get(url)
        unless response.class == Net::HTTPNotFound
          data = response.body
          CSV.parse(data, {headers: true}) do |row|
            columns = row.fields
            action_data = columns[5].gsub('"', '').strip
            ex_date = find_ex_date(columns)
            stock = Stock.find_by(symbol: columns[0])
            persist_actions(action_data, parse_action(action_data), ex_date, stock) if stock
          end
        end
      end

      def find_ex_date(columns)
        [6, 7, 8].each do |index|
          columns[index].gsub!('"', ' ') unless columns[index].nil?
          columns[index].strip! unless columns[index].nil?
        end
        ex_date_str = columns[6]
        record_date_str = (columns[7] == '-' ? columns[8] : columns[7])
        ex_date_str != '-' ? Date.parse(ex_date_str) : Date.parse(record_date_str) - 1
      end

      def parse_action(actions_data)
        parsed_actions = []
        actions_data.split(/AND/i).each do |action_split|
          action_split.gsub!('/-', '')
          action_split.gsub!(/(\d)\//) { |match| "#{$1}" }
          action_split.gsub!('//', '/')
          action_split.strip!
          action_split.split(/\//).each do |action|
            if action =~ /(DIV|DV|SPECIAL|FINAL)/i
              action.split('+').each { |split_action| parsed_actions << parse_dividend(split_action) }
            elsif action =~ /SPL|FV/i
              parsed_actions << parse_split(action)
            elsif action =~ /BON/i && !(action =~ /DEBENTURES/i)
              parsed_actions << parse_bonus(action)
            elsif action =~ /CONSOLIDATION/i
              parsed_actions << parse_consolidation(action)
            elsif action =~ /AGM|ANNUAL|ANN|Interest|SCH|RHT|RIGHT|RIGTHS|RGTS|RH|RGHT|RIGTS|EGM|ELECTION|ELCTN|ELEC|GENERAL|CAPITAL|CAPT|REDEMPTION|DEBENTURES|REVISED|ARNGMNT|-|WARRANT|WRNT|WAR|BK\sCL|FCD|CCPS/i
              parsed_actions << {type: :ignore, data: action}
            else
              parsed_actions << {type: :unknown, data: action}
            end
          end
        end
        parsed_actions
      end
    end
  end
end
