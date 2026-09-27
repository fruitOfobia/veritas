class Admin::CouponsController < Admin::BaseController
  before_action :set_coupon, only: [ :edit, :update, :destroy ]

  def index
    @coupons = Coupon.order(created_at: :desc)
  end

  def new
    @coupon = Coupon.new
  end

  def create
    @coupon = Coupon.new(coupon_params)

    if @coupon.save
      redirect_to admin_coupons_path, notice: "Coupon created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @coupon.update(coupon_params)
      redirect_to admin_coupons_path, notice: "Coupon updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coupon.destroy
    redirect_to admin_coupons_path, notice: "Coupon deleted."
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:code, :discount_type, :discount_value, :min_order_amount,
      :max_discount_amount, :usage_limit, :valid_from, :valid_until, :is_active)
  end
end
