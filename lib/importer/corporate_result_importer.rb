module Importer
  class CorporateResultImporter
    include NseConnection

    def import
      stocks = Stock.all(order: :symbol, conditions: "series = 'e'")
      stocks.each do |stock|
        p "Results for : #{stock.symbol}"
        begin
          response = get("/corporates/corpInfo/equities/resHistory.jsp?symbol=#{CGI.escape(stock.symbol)}")
          next if response.class == Net::HTTPNotFound
          data = response.body
          doc = Nokogiri::HTML(data)
          tables = doc.css('.viewTable')
          quarter_ends = extract_quarter_ends(tables[0])
          financial_data = extract_financial_data(tables[1])
          quarter_ends.each_with_index do |quarter, index|
            corporate_result = CorporateResult.find_or_create_by_stock_id_and_quarter_end(stock.id, quarter)
            corporate_result.update_attributes! financial_data[index]
          end
        rescue => e
          p "Error importing company financial info for #{stock.symbol} #{e.inspect}"
        end
      end
    end

    def extract_quarter_ends table
      tds = table.css('tr')[0].css('td')
      tds.shift #skip title
      quarter_ends = tds.collect {|td| Date.parse(td.text)}
    end
    def extract_financial_data table
      financial_data = []
      table.css('tr').each do |tr|
        tds = tr.css('td')
        header_td = tds.shift.text
        header = nil
        header = 'net_sales' if header_td =~ /Net Sales/
        header = 'net_p_and_l' if header_td =~ /Net Profit \(\_\)\/Loss\(\-\) for the period/
        header = 'eps_before_extraordinary' if header_td =~ /Diluted EPS before Extraordinary items/
        header = 'eps' if header_td =~ /Diluted EPS after Extraordinary items/i
        next if header.nil?
        tds.each_with_index do |td, index|
          financial_data[index] ||= {}
          financial_data[index][header] = td.text.to_f
        end
      end
      financial_data
    end
  end
end
