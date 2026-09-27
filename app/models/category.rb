class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :subcategories
  has_many :subcategories, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :top_level, -> { where(parent_id: nil) }
  scope :active, -> { where(is_active: true) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end

  def top_level?
    parent_id.nil?
  end

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
