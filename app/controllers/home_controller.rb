class HomeController < ApplicationController
  def index
    @top_categories = Category.visible.top_level.ordered.limit(12)
    @featured_products = Product.visible.featured.includes(:category, images_attachments: :blob).limit(8)
    @new_arrivals = Product.visible.includes(:category, images_attachments: :blob).order(created_at: :desc).limit(8)
  end
end
