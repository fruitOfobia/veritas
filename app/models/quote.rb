class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_items, dependent: :destroy
  has_many :products, through: :quote_items

  accepts_nested_attributes_for :quote_items, reject_if: :all_blank, allow_destroy: true

  enum :status, { pending: 0, quoted: 1, accepted: 2, rejected: 3 }, default: :pending

  validates :quote_number, presence: true, uniqueness: true
  validates :quote_items, presence: true

  before_validation :generate_quote_number, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def total_quoted_amount
    quote_items.sum { |item| (item.quoted_unit_price || 0) * item.quantity }
  end

  def fully_quoted?
    quote_items.all? { |item| item.quoted_unit_price.present? }
  end

  private

  def generate_quote_number
    self.quote_number ||= "QT#{Time.current.strftime('%y%m%d')}#{SecureRandom.hex(3).upcase}"
  end
end
