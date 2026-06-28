require "rails_helper"

RSpec.describe Checks::VpnTor do
  subject(:result) { described_class.new(ip: ip, client: client).call }

  let(:ip) { "203.0.113.10" }
  let(:client) { instance_double(VpnApiClient, lookup: api_response) }

  context "when VPNAPI identifies VPN" do
    let(:api_response) { VpnApiClient::Response.new(vpn: true, tor: false, proxy: false) }

    it "bans and preserves network flags for logging" do
      expect(result).to eq(
        banned: true,
        reason: "vpn_or_tor",
        vpn: true,
        tor: false,
        proxy: false
      )
    end
  end

  context "when VPNAPI identifies Tor" do
    let(:api_response) { VpnApiClient::Response.new(vpn: false, tor: true, proxy: false) }

    it "bans and preserves network flags for logging" do
      expect(result).to eq(
        banned: true,
        reason: "vpn_or_tor",
        vpn: false,
        tor: true,
        proxy: false
      )
    end
  end

  context "when VPNAPI returns a clean IP" do
    let(:api_response) { VpnApiClient::Response.new(vpn: false, tor: false, proxy: true) }

    it "passes and returns network details" do
      expect(result).to eq(
        banned: false,
        vpn: false,
        tor: false,
        proxy: true
      )
    end
  end

  context "when VPNAPI fails" do
    let(:api_response) { nil }

    it "fails open" do
      expect(result).to eq(
        banned: false,
        vpn: false,
        tor: false,
        proxy: false
      )
    end
  end
end
