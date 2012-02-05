require 'net/http'
require 'nokogiri'


module Importer
  class MarketActivityImporter
    include Connectable
    SEBI_URL = URI.parse('http://www.sebi.gov.in/sebiweb/investment/FIITrendsNew.jsp')

    def import
      start_date = ((MarketActivity.maximum('date') or Date.parse('31/12/2009')) + 1.day)
      today = Date.today
      while(start_date.beginning_of_month < today.beginning_of_month)
        start_date = start_date.end_of_month
        load_data_for_month_upto(start_date)
        start_date = start_date + 1
      end
      load_data_for_month_upto(today)
    end

    private

    def load_data_for_month_upto(start_date)
      params = {txtCalendar: start_date.strftime('%d/%m/%Y')}
      resp, data = Net::HTTP.post_form(SEBI_URL, params)
      parse(data)
    end

    def parse(data)
      doc = Nokogiri::HTML(data)
      data_rows = doc.css('.defaultTxtFII')
      index = 0
      while (index < data_rows.count)
        row = data_rows[index]
        tds = row.css('td')

        if tds[1].content == 'Equity'
          begin index += 3; next end if tds.first.content =~ /Cumulative/
          begin index += 7; next end if tds.first.content =~ /Total/
          load_equity_data(index, data_rows)
          index += tds.first.attr('rowspan').to_i
        else
          begin index += 5; next end if tds.first.content =~ /Total/
          load_fo_data(index, data_rows)
          index += 5
        end
      end
    end

    def load_equity_data(index, data_rows)
      date = find_date(index, data_rows)
      total_equity_row_data = data_rows[index + 2].css('td')
      total_debit_row_data = data_rows[index + 5].css('td')
      market_activity = MarketActivity.find_or_create_by_date(date)
      market_activity.update_attributes!('fii_buy_equity' => total_equity_row_data[1].content,
                                        'fii_sell_equity' => total_equity_row_data[2].content,
                                        'fii_buy_debit' => total_debit_row_data[1].content,
                                        'fii_sell_debit' => total_debit_row_data[2].content)
    end

    def find_date(index, data_rows)
      Date.parse(data_rows[index].css('td').first.content)
    end

    def load_fo_data(index, data_rows)
      date = find_date(index, data_rows)
      market_activity = MarketActivity.find_by_date(date)
      return unless market_activity
      [:index_futures, :index_options, :stock_futures, :stock_options].each_with_index do |data_type, sub_index|
        row_data = data_rows[index + sub_index].css('td')
        market_activity.update_attributes!("fii_#{data_type}_buy" => row_data[3].content,
                                           "fii_#{data_type}_sell" => row_data[5].content,
                                           "fii_#{data_type}_oi" => row_data[6].content,
                                           "fii_#{data_type}_oi_value" => row_data[7].content)
      end
    end
  end
end