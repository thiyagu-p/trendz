module Importer
  module Connectable
    def connection(host)
      @http ||= create_connection(host)
    end

    private
    def create_connection(host)
      if (ENV['http_proxy'])
        uri = URI.parse(ENV['http_proxy'])
        proxy_user, proxy_pass = uri.userinfo ? uri.userinfo.split(/:/) : [nil, nil]
        Net::HTTP::Proxy(uri.host, uri.port, proxy_user, proxy_pass).new(host)
      else
        Net::HTTP.new(host)
      end
    end
  end
end