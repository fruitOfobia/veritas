FactoryBot.define do
  factory :payment do
    order
    payment_method { :cod }
    status { :pending }
    amount { 100.0 }
  end
end
