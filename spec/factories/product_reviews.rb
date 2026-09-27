FactoryBot.define do
  factory :product_review do
    product
    user
    rating { 5 }
    comment { "Great product!" }
  end
end
