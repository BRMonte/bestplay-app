require "rails_helper"

RSpec.describe IntegrityLog, type: :model do
  describe "validations" do
    it "requires idfa" do
      log = build(:integrity_log, idfa: nil)

      expect(log).not_to be_valid
    end

    it "requires ban_status" do
      log = build(:integrity_log, ban_status: nil)

      expect(log).not_to be_valid
    end
  end

  describe "timestamps" do
    it "sets created_at on create" do
      log = create(:integrity_log)

      expect(log.created_at).to be_present
    end

    it "does not track updated_at" do
      log = create(:integrity_log)

      expect(log).not_to respond_to(:updated_at)
    end
  end
end
