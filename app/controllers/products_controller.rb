class ProductsController < ApplicationController
  def index
    scope = Product.visible.includes(:category, images_attachments: :blob).search(params[:q])
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = apply_filters(scope)

    @pagy, @products = pagy(scope, limit: 24)
    @categories = Category.visible.top_level.ordered
  end

  def show
    @product = Product.visible.includes(:category, images_attachments: :blob, product_reviews: :user).find_by!(slug: params[:slug])
    @related_products = Product.visible.where(category_id: @product.category_id).where.not(id: @product.id).limit(4)
    @review = ProductReview.new
  end

  # Live search-as-you-type dropdown, fetched from the header search box.
  def suggestions
    query = params[:q].to_s.strip

    if query.length < 2
      @products = Product.none
      @categories = Category.none
    else
      @products = Product.visible.includes(:category, images_attachments: :blob).search(query).limit(6)
      @categories = Category.visible.where("categories.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(query)}%").limit(3)
    end

    render partial: "products/suggestions", locals: { query: query, products: @products, categories: @categories }, layout: false
  end

  private

  def apply_filters(scope)
    scope = scope.where("price >= ?", params[:min_price]) if params[:min_price].present?
    scope = scope.where("price <= ?", params[:max_price]) if params[:max_price].present?

    case params[:sort]
    when "price_asc" then scope.order(price: :asc)
    when "price_desc" then scope.order(price: :desc)
    when "newest" then scope.order(created_at: :desc)
    else scope.order(is_featured: :desc, created_at: :desc)
    end
  end
end
