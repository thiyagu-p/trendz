module Importer
  module CorporateActionParser
    private

    def persist_actions(action_data, actions, ex_date, stock)
      actions.each do |action|
        if action[:type] == :dividend
          dividend = DividendAction.find_or_initialize_by(stock_id: stock.id, ex_date: ex_date, percentage: action[:percentage], value: action[:value])
          dividend.update_attributes!(nature: action[:nature])
        elsif action[:type] == :bonus
          bonus = BonusAction.find_or_initialize_by(stock_id: stock.id, ex_date: ex_date)
          bonus.update_attributes!(holding_qty: action[:holding], bonus_qty: action[:bonus])
        elsif action[:type] == :split or action[:type] == :consolidation
          split = FaceValueAction.find_or_initialize_by(stock_id: stock.id, ex_date: ex_date)
          split.update_attributes!(from: action[:from], to: action[:to])
        else
          corporate_action_error = CorporateActionError.find_or_initialize_by(stock_id: stock.id, ex_date: ex_date, partial_data: action[:data])
          corporate_action_error.update_attributes!(full_data: action_data, partial_data: action[:data], is_ignored: (action[:type] == :ignore))
        end
      end
    end

    def parse_dividend(action)
      parsed_data = {type: :dividend}
      dividend_nature = {'SP' => :SPECIAL, 'FI' => :FINAL, 'INT' => :INTERIM, 'DIV' => :DIVIDEND, 'DV' => :DIVIDEND}
      if action =~ /(SP|FI|INT)/i
        parsed_data[:nature] = dividend_nature[$1.upcase]
      elsif action =~ /(DIV|DV)/i
        parsed_data[:nature] = dividend_nature[$1.upcase]
      else
        parsed_data[:nature] = :UNKNOWN
      end
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
      parsed_data = {type: :split}
      parsed_data[:type] = :split
      if action =~ /(\d+).*?TO.*?(\d+)/i || action =~ /(\d+).*?-.*?(\d+)/
        parsed_data[:from] = $1
        parsed_data[:to] = $2
      else
        parsed_data = {type: :unknown, data: action}
      end
      parsed_data
    end

    def parse_bonus(action)
      parsed_data = {type: :bonus}
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
      if action =~ /(\d+).*?TO.*?(\d+)/i
        parsed_data[:from] = $1
        parsed_data[:to] = $2
      else
        parsed_data = {type: :ignore, data: action}
      end
      parsed_data
    end
  end
end