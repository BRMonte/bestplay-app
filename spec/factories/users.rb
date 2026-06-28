FactoryBot.define do
  factory :user do
    sequence(:idfa) { |n| format("%08x-be95-4b2b-b260-6ee98dd53bf%02x", n, n) }
    ban_status { User::NOT_BANNED }

    trait :banned do
      ban_status { User::BANNED }
    end
  end
end
