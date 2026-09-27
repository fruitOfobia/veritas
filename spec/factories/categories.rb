FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    description { "A sample category." }
    position { 0 }
    is_active { true }
  end
end
