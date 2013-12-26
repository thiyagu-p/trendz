module Importer
  module Nse
    class NiftyLiveImporter
      include Connection

      def import
        begin
          response = get('/live_market/dynaContent/live_watch/stock_watch/liveIndexWatchData.json')
          return if response.class == Net::HTTPNotFound
          parse(response.body)
        rescue => e
          Rails.logger.error e.inspect
        end
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
        return unless EqQuote.find_by_date date
        quote = EqQuote.find_or_create_by(stock_id: nifty.id, date: date)
        attr_hash = ["open", "high", "low", "close"].inject({}) { |attr_hash, value| attr_hash[value] = parse_data(nifty_data, value); attr_hash }
        quote.update_attributes!(attr_hash)
        MovingAverageCalculator.update(date, nifty)
      end
    end
  end
end
