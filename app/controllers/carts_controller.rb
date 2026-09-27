class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart_items = current_cart.cart_items.includes(product: { images_attachments: :blob })
  end

  def add_item
    product = Product.visible.find(params[:product_id])
    current_cart.add_product(product, quantity: (params[:quantity] || 1).to_i)

    respond_to do |format|
      format.html { redirect_back fallback_location: product_path(product), notice: "Added to cart." }
      format.turbo_stream
    end
  end

  def update_item
    item = current_cart.cart_items.find(params[:item_id])
    quantity = params[:quantity].to_i

    if quantity <= 0
      item.destroy
    else
      item.update(quantity: quantity)
    end

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.turbo_stream
    end
  end

  def remove_item
    item = current_cart.cart_items.find(params[:item_id])
    item.destroy

    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Removed from cart." }
      format.turbo_stream
    end
  end
end
