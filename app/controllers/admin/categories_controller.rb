class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [ :show, :edit, :update, :destroy ]

  def index
    @categories = Category.includes(:parent).order(:position, :name)
  end

  def show
    @subcategories = @category.subcategories.ordered
    @products = @category.products.includes(images_attachments: :blob).order(:name)
  end

  def new
    @category = Category.new
    @parent_categories = Category.top_level.ordered
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: "Category created."
    else
      @parent_categories = Category.top_level.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @parent_categories = Category.top_level.ordered.where.not(id: @category.id)
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path, notice: "Category updated."
    else
      @parent_categories = Category.top_level.ordered.where.not(id: @category.id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to admin_categories_path, notice: "Category deleted."
  end

  private

  # Category#to_param returns the slug, so admin URLs carry slugs rather than ids.
  # Numeric ids are still accepted for hand-typed/bookmarked URLs.
  def set_category
    @category = Category.find_by(slug: params[:id]) || Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :description, :parent_id, :position, :is_active)
  end
end
