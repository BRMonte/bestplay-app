module Checks
  class VpnTor
    def initialize(ip:, client: VpnApiClient.new)
      @ip = ip
      @client = client
    end

    def call
      response = client.lookup(ip)
      return pass if response.nil?
      return banned(response) if response.vpn || response.tor

      pass_with_details(response)
    end

    private

    attr_reader :ip, :client

    def pass
      { banned: false, vpn: false, tor: false, proxy: false }
    end

    def pass_with_details(response)
      {
        banned: false,
        vpn: response.vpn,
        tor: response.tor,
        proxy: response.proxy
      }
    end

    def banned(response)
      {
        banned: true,
        reason: "vpn_or_tor",
        vpn: response.vpn,
        tor: response.tor,
        proxy: response.proxy
      }
    end
  end
end
