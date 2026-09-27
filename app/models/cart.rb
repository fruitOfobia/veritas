class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def add_product(product, quantity: 1)
    item = cart_items.find_or_initialize_by(product: product)
    item.quantity = (item.persisted? ? item.quantity : 0) + quantity
    item.save!
    item
  end

  def total_items
    cart_items.sum(:quantity)
  end

  def subtotal
    cart_items.includes(:product).sum { |item| item.product.price * item.quantity }
  end

  def empty?
    cart_items.none?
  end
end
