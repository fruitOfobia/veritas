FactoryBot.define do
  factory :quote do
    user
    status { :pending }

    after(:build) do |quote|
      quote.quote_items << build(:quote_item, quote: nil) if quote.quote_items.empty?
    end
  end
end
