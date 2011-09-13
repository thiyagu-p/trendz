module Importer
  class NiftyLiveImporter
    include NseConnection

    def import
      response = get('/homepage/Indices1.json')
      return if response.class == Net::HTTPNotFound
      parse(response.body)
    end

    private
    def parse(json)
      hash = eval(json)
      nifty_data = hash[:data].second
      stocks = Stock.find_all_by_symbol('NIFTY')
      nifty = stocks.first
      return unless nifty_data[:name] =~ /S&P CNX NIFTY/ or !nifty.nil?
      date = Date.parse(hash[:time])
      close = nifty_data[:lastPrice].gsub(',','').to_f
      quote = EqQuote.find_or_create_by_stock_id_and_date(nifty.id, date)
      quote.update_attributes!(close: close)
    end
  end
end
