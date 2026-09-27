FactoryBot.define do
  factory :coupon do
    sequence(:code) { |n| "SAVE#{n}" }
    discount_type { :percentage }
    discount_value { 10 }
    min_order_amount { 0 }
    usage_limit { 100 }
    used_count { 0 }
    valid_from { 1.day.ago }
    valid_until { 30.days.from_now }
    is_active { true }
  end
end
