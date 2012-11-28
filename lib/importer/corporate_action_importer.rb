module Importer
  class CorporateActionImporter
    include NseConnection

    def import
      stocks = Stock.all(order: :symbol, conditions: "series = 'e'")
      stocks.each do |stock|
        begin
          response = get("/marketinfo/companyinfo/eod/action.jsp?symbol=#{CGI.escape(stock.symbol)}")
          next if response.class == Net::HTTPNotFound
          data = response.body
          doc = Nokogiri::HTML(data)
          doc.css('table table table table table tr').each do |row|
            columns = row.css('td')
            next unless columns[0].text.strip =~ /EQ/
            action_data = columns[7].text
            ex_date = find_ex_date(columns)
            next if CorporateAction.find_by_raw_data_and_ex_date(action_data, ex_date)
            CorporateAction.create! stock_id: stock.id, ex_date: ex_date,
                                    parsed_data: parse_action(action_data).to_json, raw_data: action_data
          end
        rescue
          p "Error importing company info for #{stock.symbol}"
        end
      end
    end

    def find_ex_date(columns)
      ex_date_str = columns[4].text
      record_date_str = columns[1].text != '-' ? columns[1].text : columns[2].text
      ex_date_str != '-' ? Date.parse(ex_date_str) : Date.parse(record_date_str) - 1
    end

    def import_and_save_to_file
      stocks = Stock.all(order: :symbol, conditions: "series = 'e'")
      open('company_action_consolidated.csv', 'w') do |file|
        stocks.each do |stock|
          response = get("/marketinfo/companyinfo/eod/action.jsp?symbol=#{CGI.escape(stock.symbol)}")
          next if response.class == Net::HTTPNotFound
          symbol = stock.symbol
          data = response.body
          doc = Nokogiri::HTML(data)
          doc.css('table table table table table tr').each do |row|
            columns = row.css('td')
            next unless columns[0].text.strip =~ /EQ/
            file << "#{symbol}|#{columns[0].text}|#{columns[4].text}|#{columns[7].text}\n"
          end
        end
      end
    end

    def parse_action(actions_data)
      parsed_actions = []
      actions_data.split('AND').each do |action_split|
        action_split.gsub!('/-', '')
        action_split.gsub!(/(\d)\//) {|match| "#{$1}"}
        action_split.gsub!('//', '/')
        action_split.strip!
        action_split.split(/\//).each do |action|
          if action =~ /(DIV|DV|SPECIAL|FINAL)/i
            action.split('+').each { |split_action| parsed_actions << parse_divident(split_action) }
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

    private
    def parse_divident(action)
      parsed_data = {}
      parsed_data[:type] = :divident
      if action =~ /(\d+\.\d*)%/ix
        parsed_data[:percentage] = $1
      elsif action =~ /(\d+)%/ix
        parsed_data[:percentage] = $1
      elsif action =~ /(\d+\.\d*)/ix
        parsed_data[:value] = $1
      elsif action =~ /(\d+)/ix
        parsed_data[:value] = $1
      elsif action =~ /NIL/i
        parsed_data = {type: :ignore, data: action}
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

    def parse_split(action)
      parsed_data = {}
      parsed_data[:type] = :split
      if action =~ /(\d+).*?TO.*?(\d+)/ || action =~ /(\d+).*?-.*?(\d+)/
        parsed_data[:from] = $1
        parsed_data[:to] = $2
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

    def parse_bonus(action)
      parsed_data = {}
      parsed_data[:type] = :bonus
      if action =~ /(\d+).*?:.*?(\d+)/
        parsed_data[:bonus] = $1
        parsed_data[:holding] = $2
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

    def parse_consolidation(action)
      parsed_data = {}
      parsed_data[:type] = :consolidation
      if action =~ /(\d+).*?TO.*?(\d+)/
        parsed_data[:from] = $1
        parsed_data[:to] = $2
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

  end
end
