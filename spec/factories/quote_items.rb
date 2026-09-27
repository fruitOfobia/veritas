FactoryBot.define do
  factory :quote_item do
    quote
    product
    quantity { 1 }
  end
end
