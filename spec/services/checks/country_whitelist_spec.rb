require "rails_helper"

RSpec.describe Checks::CountryWhitelist do
  subject(:result) { described_class.new(country: country).call }

  before { CountryWhitelist.reset!(%w[US BR]) }

  context "when country is whitelisted" do
    let(:country) { "US" }

    it { is_expected.to eq(banned: false) }
  end

  context "when country is not whitelisted" do
    let(:country) { "RU" }

    it { is_expected.to eq(banned: true, reason: "country_not_whitelisted") }
  end

  context "when country header is missing" do
    let(:country) { nil }

    it { is_expected.to eq(banned: true, reason: "country_not_whitelisted") }
  end
end
