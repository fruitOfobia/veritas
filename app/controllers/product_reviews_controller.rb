class ProductReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    @product = Product.find_by!(slug: params[:product_slug])
    @review = @product.product_reviews.new(review_params.merge(user: current_user))

    if @review.save
      redirect_to @product, notice: "Thanks for your review!"
    else
      redirect_to @product, alert: @review.errors.full_messages.to_sentence
    end
  end

  def destroy
    @review = ProductReview.find(params[:id])
    authorize_owner!(@review)
    @review.destroy
    redirect_to @review.product, notice: "Review removed."
  end

  private

  def review_params
    params.require(:product_review).permit(:rating, :comment)
  end

  def authorize_owner!(review)
    return if review.user_id == current_user.id || current_user.admin?

    redirect_to root_path, alert: "Not authorized." and return
  end
end
