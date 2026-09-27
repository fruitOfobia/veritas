FactoryBot.define do
  factory :address do
    user
    label { "Home" }
    line1 { "1 Main Street" }
    city { "Bengaluru" }
    state { "Karnataka" }
    pincode { "560001" }
    is_default { true }
  end
end
