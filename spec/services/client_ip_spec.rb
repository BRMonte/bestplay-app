require "rails_helper"

RSpec.describe ClientIp do
  it "prefers CF-Connecting-IP over remote_ip" do
    ip = described_class.from(
      headers: { "CF-Connecting-IP" => "198.51.100.20" },
      remote_ip: "203.0.113.1"
    )

    expect(ip).to eq("198.51.100.20")
  end

  it "falls back to remote_ip when CF-Connecting-IP is absent" do
    ip = described_class.from(headers: {}, remote_ip: "203.0.113.1")

    expect(ip).to eq("203.0.113.1")
  end
end
