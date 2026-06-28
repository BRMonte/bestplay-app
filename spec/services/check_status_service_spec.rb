require "rails_helper"

RSpec.describe CheckStatusService do
  subject(:service_call) do
    described_class.new(
      idfa: idfa,
      rooted_device: rooted_device,
      ip: ip,
      country: country,
      logger: logger
    ).call
  end

  let(:idfa) { "8264148c-be95-4b2b-b260-6ee98dd53bf6" }
  let(:rooted_device) { false }
  let(:ip) { "203.0.113.10" }
  let(:country) { "US" }
  let(:logger) { instance_double(IntegrityLogger, log: true) }

  before do
    CountryWhitelist.reset!(%w[US BR])
    stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{ENV.fetch("VPNAPI_KEY")}").to_return(
      status: 200,
      body: { security: { vpn: false, tor: false, proxy: false } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  context "when the user is new and passes all checks" do
    it "creates the user, logs once, and returns not_banned" do
      expect { service_call }.to change(User, :count).by(1)

      expect(service_call).to eq(ban_status: User::NOT_BANNED)
      expect(logger).to have_received(:log).once
      expect(User.find_by(idfa: idfa).ban_status).to eq(User::NOT_BANNED)
    end
  end

  context "when the user is new and fails a check" do
    let(:country) { "RU" }

    it "creates a banned user and logs the result" do
      expect { service_call }.to change(User, :count).by(1)

      expect(service_call).to eq(ban_status: User::BANNED)
      expect(logger).to have_received(:log).once
    end
  end

  context "when an existing user is already banned" do
    before { create(:user, :banned, idfa: idfa) }

    it "skips checks and returns banned without logging" do
      expect(service_call).to eq(ban_status: User::BANNED)
      expect(logger).not_to have_received(:log)
      expect(WebMock).not_to have_requested(:get, /vpnapi/)
    end
  end

  context "when an existing not_banned user stays not_banned" do
    before { create(:user, idfa: idfa, ban_status: User::NOT_BANNED) }

    it "re-runs checks without creating a new log" do
      expect { service_call }.not_to change(User, :count)

      expect(service_call).to eq(ban_status: User::NOT_BANNED)
      expect(logger).not_to have_received(:log)
    end
  end

  context "when an existing not_banned user becomes banned" do
    before { create(:user, idfa: idfa, ban_status: User::NOT_BANNED) }

    let(:rooted_device) { true }

    it "updates the user and logs the status change" do
      expect(service_call).to eq(ban_status: User::BANNED)
      expect(User.find_by(idfa: idfa).ban_status).to eq(User::BANNED)
      expect(logger).to have_received(:log).once
    end
  end

  context "when VPNAPI fails" do
    before do
      stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{ENV.fetch("VPNAPI_KEY")}").to_return(status: 500)
    end

    it "fails open and keeps the user not banned" do
      expect(service_call).to eq(ban_status: User::NOT_BANNED)
    end
  end

  context "when the user is banned by VPN" do
    let(:logger) { IntegrityLogger.new }

    before do
      stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{ENV.fetch("VPNAPI_KEY")}").to_return(
        status: 200,
        body: { security: { vpn: true, tor: false, proxy: false } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "persists vpn=true in the integrity log" do
      service_call

      log = IntegrityLog.last
      expect(log.ban_status).to eq(User::BANNED)
      expect(log.vpn).to be(true)
      expect(log.proxy).to be(false)
    end
  end
end
