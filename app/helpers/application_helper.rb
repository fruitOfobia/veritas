module ApplicationHelper
  include Pagy::Frontend

  def currency(amount)
    number_to_currency(amount || 0, unit: "₹", precision: 0, delimiter: ",")
  end

  def star_rating(rating)
    rating = rating.to_f.round
    (("★" * rating) + ("☆" * (5 - rating)))
  end

  def product_thumbnail(product, variant: :thumb)
    return nil unless product.images.attached?

    product.images.first
  end

  def nav_categories
    @nav_categories ||= Category.visible.top_level.ordered.includes(:subcategories)
  end
end
