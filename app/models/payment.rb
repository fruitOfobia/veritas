class Payment < ApplicationRecord
  belongs_to :order

  enum :payment_method, { cod: 0, razorpay: 1 }, default: :cod
  enum :status, { pending: 0, paid: 1, failed: 2, refunded: 3 }, default: :pending
end
