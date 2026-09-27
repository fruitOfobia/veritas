class Admin::OrdersController < Admin::BaseController
  before_action :set_order, only: [ :show, :update ]

  def index
    @pagy, @orders = pagy(Order.includes(:user).recent, limit: 25)
  end

  def show
  end

  def update
    if @order.update(status: params[:order][:status])
      redirect_to admin_order_path(@order), notice: "Order status updated."
    else
      redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
  end
end
