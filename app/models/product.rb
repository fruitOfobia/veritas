class Product < ApplicationRecord
  belongs_to :category
  has_many :cart_items, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :order_items, dependent: :nullify
  has_many :quote_items, dependent: :destroy
  has_many :product_reviews, dependent: :destroy
  has_many_attached :images

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :sku, presence: true, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { greater_than_or_equal_to: 0 }

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :active, -> { where(is_active: true) }
  scope :featured, -> { where(is_featured: true) }
  scope :in_stock, -> { where("stock > 0") }
  scope :search, ->(query) {
    next all if query.blank?

    sanitized = sanitize_sql_like(query)
    where("products.name ILIKE :q OR products.description ILIKE :q", q: "%#{sanitized}%")
  }

  def to_param
    slug
  end

  def discount_percent
    return 0 if mrp.blank? || mrp <= 0 || price.blank? || price >= mrp

    (((mrp - price) / mrp) * 100).round
  end

  def on_sale?
    discount_percent > 0
  end

  def in_stock?
    stock.to_i > 0
  end

  def average_rating
    product_reviews.average(:rating)&.round(1) || 0
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
