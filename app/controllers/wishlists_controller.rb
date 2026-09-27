class WishlistsController < ApplicationController
  before_action :authenticate_user!

  def show
    @wishlist_items = current_wishlist.wishlist_items.includes(product: { images_attachments: :blob })
  end

  def toggle
    product = Product.find(params[:product_id])
    added = current_wishlist.toggle(product)

    respond_to do |format|
      format.html { redirect_back fallback_location: product_path(product), notice: added ? "Added to wishlist." : "Removed from wishlist." }
      format.turbo_stream
    end
  end
end
