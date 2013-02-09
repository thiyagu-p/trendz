require 'net/http'

module Importer
  module Nse
    module Connection
      include Importer::Connectable

      def self.user_agent
        {'User-Agent' => 'Firefox'}
      end

      def get(path)
        connection(NSE_URL).request_get(path, Connection.user_agent)
      end
    end
  end
end