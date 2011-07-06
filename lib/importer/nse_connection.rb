require 'net/http'

module Importer
  module NseConnection
    def self.user_agent
      {'User-Agent'=>'Firefox'}
    end

    def get(path)
      connection.request_get(path, NseConnection.user_agent)
    end

    def connection
      @http ||= Net::HTTP.new(NSE_URL)
    end
  end
end