class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [ :show, :cancel ]

  def index
    @orders = current_user.orders.recent.includes(:order_items)
  end

  def new
    redirect_to cart_path, alert: "Your cart is empty." and return if current_cart.empty?

    @order = current_user.orders.new
    @addresses = current_user.addresses.order(is_default: :desc)
    @cart_items = current_cart.cart_items.includes(:product)
    @coupon = Coupon.active.find_by(code: params[:coupon_code]&.upcase) if params[:coupon_code].present?
  end

  def create
    redirect_to cart_path, alert: "Your cart is empty." and return if current_cart.empty?

    address = current_user.addresses.find(order_params[:address_id])
    coupon = Coupon.active.find_by(code: order_params[:coupon_code]&.upcase)

    order = build_order(address, coupon)

    if order.save
      current_cart.cart_items.destroy_all
      redirect_to order_path(order), notice: "Order placed successfully!"
    else
      redirect_to new_order_path, alert: order.errors.full_messages.to_sentence
    end
  end

  def show
  end

  def cancel
    if @order.cancellable?
      @order.update!(status: :cancelled)
      redirect_to order_path(@order), notice: "Order cancelled."
    else
      redirect_to order_path(@order), alert: "This order can no longer be cancelled."
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:address_id, :payment_method, :coupon_code, :notes)
  end

  def build_order(address, coupon)
    subtotal = current_cart.subtotal
    discount = coupon&.discount_for(subtotal) || 0

    order = current_user.orders.new(
      address: address,
      coupon: coupon,
      payment_method: order_params[:payment_method] || :cod,
      notes: order_params[:notes],
      subtotal: subtotal,
      discount_amount: discount,
      shipping_amount: 0,
      total: subtotal - discount,
      placed_at: Time.current
    )

    current_cart.cart_items.includes(:product).each do |item|
      order.order_items.build(
        product: item.product,
        product_name: item.product.name,
        quantity: item.quantity,
        unit_price: item.product.price,
        total_price: item.product.price * item.quantity
      )
    end

    order
  end
end
