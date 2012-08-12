module Importer
  class CorporateActionImporter
    include NseConnection
    def self.check
      open('company_action_consolidated.csv').readlines.each do |line|
        actions_data = line.split('|').last
        str = CorporateActionImporter.new.parse_action(actions_data).to_s
        p "#{line}" if str =~ /unknown/
      end
      ''
    end

    def import
      stocks = Stock.all(order: :symbol, conditions: "series = 'e'")
      stocks.each do |stock|
        response = get("/marketinfo/companyinfo/eod/action.jsp?symbol=#{CGI.escape(stock.symbol)}")
        next if response.class == Net::HTTPNotFound
        symbol = stock.symbol
        data = response.body
        doc = Nokogiri::HTML(data)
        doc.css('table table table table table tr').each do |row|
          columns = row.css('td')
          next unless columns[0].text.strip =~ /EQ/
          #file << "#{symbol}|#{columns[0].text}|#{columns[4].text}|#{columns[7].text}\n"
        end
      end
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
          elsif action =~ /AGM|ANNUAL|SCH|RHT|RIGHT|RIGTHS|RGTS|RHS|RHGT|RGHT|RIGTS|EGM|ELECTION|ELCTN|GENERAL|CAPITAL|REDEMPTION|DEBENTURES|REVISED/i
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
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

    def parse_split(action)
      parsed_data = {}
      parsed_data[:type] = :split
      if action =~ /(\d+).*?TO.*?(\d+)/
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
