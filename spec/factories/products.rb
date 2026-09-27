FactoryBot.define do
  factory :product do
    category
    sequence(:name) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    description { "A sample product." }
    price { 100.0 }
    mrp { 120.0 }
    stock { 10 }
    unit { "piece" }
    is_active { true }
    is_featured { false }
  end
end
