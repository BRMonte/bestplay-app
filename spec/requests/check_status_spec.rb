require "rails_helper"

RSpec.describe "POST /v1/user/check_status", type: :request do
  let(:headers) do
    {
      "CONTENT_TYPE" => "application/json",
      "CF-IPCountry" => country,
      "CF-Connecting-IP" => client_ip
    }
  end
  let(:country) { "US" }
  let(:idfa) { "8264148c-be95-4b2b-b260-6ee98dd53bf6" }
  let(:params) do
    {
      idfa: idfa,
      rooted_device: rooted_device
    }
  end
  let(:rooted_device) { false }
  let(:client_ip) { "198.51.100.20" }
  let(:proxy_ip) { "203.0.113.10" }

  before do
    CountryWhitelist.reset!(%w[US BR])
    stub_request(:get, /vpnapi\.io\/api\/#{Regexp.escape(client_ip)}/).to_return(
      status: 200,
      body: { security: { vpn: false, tor: false, proxy: false } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def post_check_status(body: params, extra_headers: {})
    post "/v1/user/check_status",
         params: body.to_json,
         headers: headers.merge("REMOTE_ADDR" => proxy_ip).merge(extra_headers)
  end

  it "returns not_banned for a clean new user" do
    post_check_status

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq("ban_status" => User::NOT_BANNED)
    expect(User.find_by(idfa: idfa).ban_status).to eq(User::NOT_BANNED)
  end

  it "uses CF-Connecting-IP for the VPNAPI lookup" do
    post_check_status

    expect(WebMock).to have_requested(:get, /vpnapi\.io\/api\/#{Regexp.escape(client_ip)}/)
    expect(WebMock).not_to have_requested(:get, /vpnapi\.io\/api\/#{Regexp.escape(proxy_ip)}/)
  end

  it "returns banned for a rooted device" do
    post_check_status(body: params.merge(rooted_device: true))

    expect(response.parsed_body).to eq("ban_status" => User::BANNED)
  end

  it "returns banned for a non-whitelisted country" do
    post_check_status(extra_headers: { "CF-IPCountry" => "RU" })

    expect(response.parsed_body).to eq("ban_status" => User::BANNED)
  end

  it "returns banned and logs vpn=true when VPNAPI detects VPN" do
    stub_request(:get, /vpnapi\.io\/api\/#{Regexp.escape(client_ip)}/).to_return(
      status: 200,
      body: { security: { vpn: true, tor: false, proxy: false } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    post_check_status

    expect(response.parsed_body).to eq("ban_status" => User::BANNED)
    log = IntegrityLog.find_by(idfa: idfa)
    expect(log.vpn).to be(true)
    expect(log.ban_status).to eq(User::BANNED)
  end

  it "returns banned immediately for an already banned user without calling VPNAPI" do
    create(:user, :banned, idfa: idfa)

    post_check_status

    expect(response.parsed_body).to eq("ban_status" => User::BANNED)
    expect(WebMock).not_to have_requested(:get, /vpnapi/)
  end

  it "creates an integrity log when a new user is created" do
    expect { post_check_status }.to change(IntegrityLog, :count).by(1)
  end

  it "does not create an integrity log when status does not change" do
    create(:user, idfa: idfa, ban_status: User::NOT_BANNED)

    expect { post_check_status }.not_to change(IntegrityLog, :count)
  end

  it "returns 422 when idfa is missing" do
    post_check_status(body: { rooted_device: false })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq("error" => "idfa is required")
  end

  it "returns 422 when rooted_device is missing" do
    post_check_status(body: { idfa: idfa })

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body).to eq("error" => "rooted_device is required")
  end
end
