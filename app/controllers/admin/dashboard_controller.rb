class Admin::DashboardController < Admin::BaseController
  def index
    @total_revenue = Order.where.not(status: :cancelled).sum(:total)
    @order_count = Order.count
    @pending_quotes_count = Quote.pending.count
    @product_count = Product.count
    @low_stock_products = Product.active.where("stock <= 5").order(:stock).limit(5)

    @orders_by_day = Order.group_by_day(:created_at, last: 14).count
    @revenue_by_day = Order.where.not(status: :cancelled).group_by_day(:created_at, last: 14).sum(:total)
    @orders_by_status = Order.group(:status).count
    @orders_by_payment_method = Order.group(:payment_method).count

    @recent_orders = Order.recent.includes(:user).limit(8)
    @recent_quotes = Quote.recent.includes(:user).limit(8)
  end
end
