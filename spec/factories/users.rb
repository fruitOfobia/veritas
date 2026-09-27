FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { "Jane" }
    last_name { "Doe" }
    role { :customer }

    trait :admin do
      role { :admin }
    end
  end
end
