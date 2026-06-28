require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires idfa" do
      user = build(:user, idfa: nil)

      expect(user).not_to be_valid
      expect(user.errors[:idfa]).to include("can't be blank")
    end

    it "requires unique idfa" do
      create(:user, idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6")
      duplicate = build(:user, idfa: "8264148c-be95-4b2b-b260-6ee98dd53bf6")

      expect(duplicate).not_to be_valid
    end

    it "requires ban_status" do
      user = build(:user, ban_status: nil)

      expect(user).not_to be_valid
    end
  end

  describe "defaults" do
    it "defaults ban_status to not_banned" do
      user = described_class.create!(idfa: SecureRandom.uuid)

      expect(user.ban_status).to eq(User::NOT_BANNED)
      expect(user).to be_not_banned
      expect(user).not_to be_banned
    end
  end

  describe "#banned?" do
    it "returns true when ban_status is banned" do
      user = build(:user, ban_status: User::BANNED)

      expect(user).to be_banned
    end
  end
end
