class HomeController < ApplicationController
  def index
    @top_categories = Category.active.top_level.ordered.limit(12)
    @featured_products = Product.active.featured.includes(:category, images_attachments: :blob).limit(8)
    @new_arrivals = Product.active.includes(:category, images_attachments: :blob).order(created_at: :desc).limit(8)
  end
end
