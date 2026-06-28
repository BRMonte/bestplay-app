require "rails_helper"

RSpec.describe CountryWhitelist do
  describe ".allowed?" do
    before { described_class.reset!(%w[US BR]) }

    it "returns true for whitelisted countries" do
      expect(described_class.allowed?("US")).to be(true)
      expect(described_class.allowed?("us")).to be(true)
    end

    it "returns false for non-whitelisted countries" do
      expect(described_class.allowed?("RU")).to be(false)
    end

    it "returns false for blank country" do
      expect(described_class.allowed?(nil)).to be(false)
      expect(described_class.allowed?("")).to be(false)
    end
  end
end
