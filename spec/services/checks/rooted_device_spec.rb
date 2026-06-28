require "rails_helper"

RSpec.describe Checks::RootedDevice do
  subject(:result) { described_class.new(rooted_device: rooted_device).call }

  context "when device is not rooted" do
    let(:rooted_device) { false }

    it { is_expected.to eq(banned: false) }
  end

  context "when device is rooted" do
    let(:rooted_device) { true }

    it { is_expected.to eq(banned: true, reason: "rooted_device") }
  end
end
