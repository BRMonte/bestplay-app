require "rails_helper"

RSpec.describe BestplayApp::Application do
  it "is configured as an API-only app" do
    expect(described_class.config.api_only).to be(true)
  end
end
