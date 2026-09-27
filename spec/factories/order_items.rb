FactoryBot.define do
  factory :order_item do
    order
    product
    product_name { "Sample Product" }
    quantity { 1 }
    unit_price { 100.0 }
    total_price { 100.0 }
  end
end
