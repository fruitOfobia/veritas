class Coupon < ApplicationRecord
  enum :discount_type, { percentage: 0, fixed: 1 }, default: :percentage

  has_many :orders, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :discount_value, numericality: { greater_than: 0 }

  before_validation { self.code = code.to_s.upcase.strip }

  scope :active, -> { where(is_active: true) }

  def valid_now?
    return false unless is_active?
    return false if valid_from.present? && valid_from > Time.current
    return false if valid_until.present? && valid_until < Time.current
    return false if usage_limit.present? && used_count >= usage_limit

    true
  end

  def applicable?(subtotal)
    valid_now? && subtotal >= min_order_amount.to_f
  end

  def discount_for(subtotal)
    return 0 unless applicable?(subtotal)

    amount = percentage? ? subtotal * (discount_value / 100.0) : discount_value
    amount = [ amount, max_discount_amount ].min if max_discount_amount.present?
    [ amount, subtotal ].min.round(2)
  end
end
