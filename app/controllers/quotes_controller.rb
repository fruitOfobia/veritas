class QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote, only: [ :show, :accept, :reject ]

  def index
    @quotes = current_user.quotes.recent
  end

  def new
    @quote = current_user.quotes.new(company_name: current_user.company_name)
    if params[:product_id].present? && (product = Product.visible.find_by(id: params[:product_id]))
      @quote.quote_items.build(product: product, quantity: 1)
    else
      @quote.quote_items.build
    end
  end

  def create
    @quote = current_user.quotes.new(quote_params)

    if @quote.save
      redirect_to quote_path(@quote), notice: "Quote request submitted. Our team will get back to you shortly."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @quote_items = @quote.quote_items.includes(product: { images_attachments: :blob })
  end

  def accept
    if @quote.quoted? && @quote.fully_quoted?
      order = build_order_from_quote(@quote)
      order.save!
      @quote.update!(status: :accepted, responded_at: Time.current)
      redirect_to order_path(order), notice: "Quote accepted — your order has been placed."
    else
      redirect_to quote_path(@quote), alert: "This quote is not ready to be accepted yet."
    end
  end

  def reject
    @quote.update!(status: :rejected, responded_at: Time.current)
    redirect_to quote_path(@quote), notice: "Quote rejected."
  end

  private

  def set_quote
    @quote = current_user.quotes.find(params[:id])
  end

  def quote_params
    params.require(:quote).permit(:company_name, :notes,
      quote_items_attributes: [ :id, :product_id, :quantity, :notes, :_destroy ])
  end

  def build_order_from_quote(quote)
    address = current_user.default_address || current_user.addresses.first!
    order = current_user.orders.new(address: address, payment_method: :cod)

    quote.quote_items.each do |item|
      order.order_items.build(
        product: item.product,
        product_name: item.product.name,
        quantity: item.quantity,
        unit_price: item.quoted_unit_price,
        total_price: item.quoted_unit_price * item.quantity
      )
    end

    order.subtotal = order.order_items.sum(&:total_price)
    order.total = order.subtotal
    order.placed_at = Time.current
    order
  end
end
