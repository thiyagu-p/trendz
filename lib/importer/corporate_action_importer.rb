module Importer
  class CorporateActionImporter
    include NseConnection

    def import
      stocks = Stock.all(conditions: "series = 'e'")
      stocks.each do |stock|
        response = get("/marketinfo/companyinfo/eod/action.jsp?symbol=#{CGI.escape(stock.symbol)}")
        next if response.class == Net::HTTPNotFound
        parse(stock.symbol, response.body)
      end
    end

    def parse(symbol, data)
      p symbol
      doc = Nokogiri::HTML(data)
      open('company_action_consolidated.csv', 'w+') do |file|
        doc.css('table table table table table tr').each do |row|
          columns = row.css('td')
          next unless columns[0].text.strip =~ /EQ/
          file << "#{symbol}|#{columns[0].text}|#{columns[4].text}|#{columns[7].text}\n"
        end
      end
    end
  end
end
