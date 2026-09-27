class Wishlist < ApplicationRecord
  belongs_to :user
  has_many :wishlist_items, dependent: :destroy
  has_many :products, through: :wishlist_items

  def toggle(product)
    item = wishlist_items.find_by(product: product)
    if item
      item.destroy
      false
    else
      wishlist_items.create!(product: product)
      true
    end
  end

  def includes_product?(product)
    wishlist_items.exists?(product: product)
  end
end
