require 'net/http'

module Importer
  module NseConnection
    include Connectable

    def self.user_agent
      {'User-Agent'=>'Firefox'}
    end

    def get(path)
      connection(NSE_URL).request_get(path, NseConnection.user_agent)
    end
  end
end