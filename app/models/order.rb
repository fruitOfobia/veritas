class Order < ApplicationRecord
  belongs_to :user
  belongs_to :address
  belongs_to :coupon, optional: true
  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy

  enum :status, { pending: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4 }, default: :pending
  enum :payment_method, { cod: 0, razorpay: 1 }, default: :cod

  validates :order_number, presence: true, uniqueness: true

  before_validation :generate_order_number, on: :create
  after_create :increment_coupon_usage!

  scope :recent, -> { order(created_at: :desc) }

  def cancellable?
    pending? || confirmed?
  end

  private

  def generate_order_number
    self.order_number ||= "BB#{Time.current.strftime('%y%m%d')}#{SecureRandom.hex(3).upcase}"
  end

  def increment_coupon_usage!
    coupon&.increment!(:used_count)
  end
end
