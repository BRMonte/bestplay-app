require "rails_helper"

RSpec.describe VpnApiClient do
  subject(:client) { described_class.new(api_key: "test-key") }

  let(:ip) { "203.0.113.10" }
  let(:api_url) { "https://vpnapi.io/api/#{ip}?key=test-key" }

  describe "#lookup" do
    context "when response is cached" do
      before do
        REDIS.with do |redis|
          redis.setex(
            "vpnapi:#{ip}",
            described_class::CACHE_TTL,
            { vpn: true, tor: false, proxy: false }.to_json
          )
        end
      end

      it "returns cached data without calling the API" do
        result = client.lookup(ip)

        expect(result.vpn).to be(true)
        expect(result.tor).to be(false)
        expect(WebMock).not_to have_requested(:get, api_url)
      end
    end

    context "when response is not cached" do
      before do
        stub_request(:get, api_url).to_return(
          status: 200,
          body: {
            security: { vpn: false, tor: true, proxy: false }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "fetches from VPNAPI and caches the result for 24 hours" do
        result = client.lookup(ip)

        expect(result.vpn).to be(false)
        expect(result.tor).to be(true)
        expect(REDIS.with { |redis| redis.ttl("vpnapi:#{ip}") }).to be_within(5).of(described_class::CACHE_TTL)
      end
    end

    context "when VPNAPI returns an error" do
      before do
        stub_request(:get, api_url).to_return(status: 500, body: "error")
      end

      it "returns nil so callers can fail open" do
        expect(client.lookup(ip)).to be_nil
      end
    end
  end
end
