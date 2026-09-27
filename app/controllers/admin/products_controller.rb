class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [ :show, :edit, :update, :destroy ]

  def index
    @pagy, @products = pagy(Product.includes(:category, images_attachments: :blob).order(created_at: :desc), limit: 25)
  end

  def show
    @reviews = @product.product_reviews.includes(:user).order(created_at: :desc)
    @order_items = @product.order_items.includes(:order).order(created_at: :desc).limit(10)
  end

  def new
    @product = Product.new
    @categories = Category.ordered
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to admin_products_path, notice: "Product created."
    else
      @categories = Category.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.ordered
  end

  def update
    if @product.update(product_params)
      redirect_to admin_products_path, notice: "Product updated."
    else
      @categories = Category.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to admin_products_path, notice: "Product deleted."
  end

  private

  # Product#to_param returns the slug, so admin URLs carry slugs rather than ids.
  # Numeric ids are still accepted for hand-typed/bookmarked URLs.
  def set_product
    @product = Product.find_by(slug: params[:id]) || Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :category_id, :name, :slug, :sku, :description, :price, :mrp,
      :stock, :unit, :is_active, :is_featured, images: []
    )
  end
end
