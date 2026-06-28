FactoryBot.define do
  factory :integrity_log do
    idfa { create(:user).idfa }
    ban_status { User::NOT_BANNED }
    ip { "203.0.113.1" }
    rooted_device { false }
    country { "US" }
    proxy { false }
    vpn { false }
  end
end
