module Rack
  class RealIp
    def initialize(app)
      @app = app
    end

    def call(env)
      set_real_ip(Rack::Request.new(env))
      @app.call(env)
    end

    private

    def proxy_count
      (ENV['MASTODON_PROXY_COUNT'] || 0).to_i
    end

    def set_real_ip(req)
      forwarded_for = ips_from(req.get_header('HTTP_X_FORWARDED_FOR')).reverse
      remote_addr = ips_from(req.get_header('REMOTE_ADDR')).last

      ips = [remote_addr, *forwarded_for].compact
      req.set_header("MASTODON_REAL_IP", ips[proxy_count] || remote_addr)
    end

    def ips_from(header)
      return [] unless header
      header.strip.split(/[,\s]+/).select do |ip|
        begin
          IPAddr.new(ip)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
