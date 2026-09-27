class CategoriesController < ApplicationController
  def show
    @category = Category.visible.find_by!(slug: params[:slug])
    @subcategories = @category.subcategories.active.ordered
    category_ids = [ @category.id ] + @subcategories.pluck(:id)

    scope = Product.visible.where(category_id: category_ids).includes(:category, images_attachments: :blob)
    scope = apply_filters(scope)

    @pagy, @products = pagy(scope, limit: 24)
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
