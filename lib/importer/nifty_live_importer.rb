module Importer
  class NiftyLiveImporter
    include NseConnection

    def import
      response = get('/live_market/dynaContent/live_watch/stock_watch/liveIndexWatchData.json')
      return if response.class == Net::HTTPNotFound
      parse(response.body)
    end

    private
    def parse_data(nifty_data, value)
      value = "last" if value == "close"
      nifty_data[value].gsub(',', '').to_f
    end

    def parse(json)
      hash = JSON.parse(json)
      nifty_data = hash["data"].first
      nifty = Stock.find_by_symbol('NIFTY')
      return unless nifty_data["name"] =~ /S&P CNX NIFTY/ or !nifty.nil?
      date = Date.parse(nifty_data["timeVal"])
      quote = EqQuote.find_or_create_by_stock_id_and_date(nifty.id, date)
      attr_hash = ["open", "high", "low", "close"].inject({}) {|attr_hash, value| attr_hash[value] = parse_data(nifty_data, value); attr_hash }
      quote.update_attributes!(attr_hash)
      MovingAverageCalculator.update(date, nifty)
    end
  end
end
