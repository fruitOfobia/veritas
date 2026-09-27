FactoryBot.define do
  factory :order do
    user
    address
    status { :pending }
    payment_method { :cod }
    subtotal { 100.0 }
    discount_amount { 0 }
    shipping_amount { 0 }
    total { 100.0 }
  end
end
