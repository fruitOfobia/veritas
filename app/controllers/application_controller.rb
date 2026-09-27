class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pagy::Backend

  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :current_cart, :current_wishlist, :cart_item_count, :wishlist_product_ids

  def current_cart
    return nil unless user_signed_in?

    @current_cart ||= current_user.cart || current_user.create_cart!
  end

  def current_wishlist
    return nil unless user_signed_in?

    @current_wishlist ||= current_user.wishlist || current_user.create_wishlist!
  end

  def cart_item_count
    current_cart&.total_items.to_i
  end

  def wishlist_product_ids
    @wishlist_product_ids ||= current_wishlist&.products&.pluck(:id) || []
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :last_name, :company_name, :gstin ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :first_name, :last_name, :company_name, :gstin ])
  end
end
