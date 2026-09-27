class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_items, dependent: :destroy
  has_many :products, through: :quote_items

  accepts_nested_attributes_for :quote_items, reject_if: :all_blank, allow_destroy: true

  enum :status, { pending: 0, quoted: 1, accepted: 2, rejected: 3 }, default: :pending

  validates :quote_number, presence: true, uniqueness: true
  validates :quote_items, presence: true
  validate :no_duplicate_products

  before_validation :generate_quote_number, on: :create

  scope :recent, -> { order(created_at: :desc) }

  def total_quoted_amount
    quote_items.sum { |item| (item.quoted_unit_price || 0) * item.quantity }
  end

  def fully_quoted?
    quote_items.all? { |item| item.quoted_unit_price.present? }
  end

  private

  # Per-item uniqueness can't catch rows submitted together in one nested form,
  # since none of them are in the database yet — so check the in-memory set too.
  def no_duplicate_products
    names = quote_items.reject(&:marked_for_destruction?)
                       .group_by(&:product_id)
                       .select { |product_id, items| product_id.present? && items.size > 1 }
                       .keys
    return if names.empty?

    duplicated = Product.where(id: names).pluck(:name).to_sentence
    errors.add(:base, "Each product can only be added once — #{duplicated} is listed more than once.")
  end

  def generate_quote_number
    self.quote_number ||= "QT#{Time.current.strftime('%y%m%d')}#{SecureRandom.hex(3).upcase}"
  end
end
