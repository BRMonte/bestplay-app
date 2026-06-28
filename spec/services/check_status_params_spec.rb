require "rails_helper"

RSpec.describe CheckStatusParams do
  subject(:parsed) do
    described_class.new(
      ActionController::Parameters.new(params),
      headers: headers,
      remote_ip: "203.0.113.1"
    )
  end

  let(:headers) { { "CF-IPCountry" => "US", "CF-Connecting-IP" => "198.51.100.20" } }
  let(:params) do
    {
      idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6",
      rooted_device: false
    }
  end

  it "parses valid params and resolves client ip from Cloudflare header" do
    expect(parsed.idfa).to eq(params[:idfa])
    expect(parsed.rooted_device).to be(false)
    expect(parsed.ip).to eq("198.51.100.20")
    expect(parsed.country).to eq("US")
  end

  context "when idfa is missing" do
    let(:params) { { rooted_device: false } }

    it "raises an invalid params error" do
      expect { parsed }.to raise_error(described_class::Invalid, "idfa is required")
    end
  end

  context "when rooted_device is missing" do
    let(:params) { { idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6" } }

    it "raises an invalid params error" do
      expect { parsed }.to raise_error(described_class::Invalid, "rooted_device is required")
    end
  end

  context "when rooted_device is null" do
    let(:params) { { idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6", rooted_device: nil } }

    it "raises an invalid params error" do
      expect { parsed }.to raise_error(described_class::Invalid, "rooted_device must be a boolean")
    end
  end
end
