require 'csv'

module Importer
  module Nse
    class CorporateActionImporter
      include Connection
      include Importer::CorporateActionParser

      def self.url symbol
        "/corporates/datafiles/CA_#{CGI.escape(symbol)}_MORE_THAN_24_MONTHS.csv"
      end

      def import

        begin
          Stock.all(order: :symbol, conditions: "nse_active").each { |stock| fetch_data_for(stock) }
          ImportStatus.completed_upto_today ImportStatus::Source::NSE_CORPORATE_ACTION
        rescue => e
          Rails.logger.error e.inspect
          ImportStatus.failed ImportStatus::Source::NSE_CORPORATE_ACTION
        end

      end

      def fetch_data_for(stock)
        begin
          response = get(CorporateActionImporter.url stock.symbol)
          unless response.class == Net::HTTPNotFound
            data = response.body
            CSV.parse(data, {headers: true}) do |row|
              columns = row.fields
              action_data = columns[5].gsub('"', '').strip
              ex_date = find_ex_date(columns)
              persist_actions(action_data, parse_action(action_data), ex_date, stock)
            end
          end
        rescue => e
          p "Error importing company info for #{stock.symbol} #{e.inspect}"
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
            elsif action =~ /AGM|ANNUAL|ANN|SCH|RHT|RIGHT|RIGTHS|RGTS|RH|RGHT|RIGTS|EGM|ELECTION|ELCTN|ELEC|GENERAL|CAPITAL|CAPT|REDEMPTION|DEBENTURES|REVISED|ARNGMNT|-|WARRANT|WRNT|WAR|BK\sCL|FCD|CCPS/i
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
