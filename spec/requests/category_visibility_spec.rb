require "rails_helper"

# Deactivating a category in the admin panel must hide its products everywhere
# on the storefront, not just hide the category page itself.
RSpec.describe "Deactivated category visibility", type: :request do
  let!(:live_category) { create(:category, name: "Flooring", is_active: true) }
  let!(:live_product) { create(:product, category: live_category, name: "Vitrified Floor Tile") }

  let!(:disabled_category) { create(:category, name: "Kitchen", is_active: false) }
  let!(:hidden_product) { create(:product, category: disabled_category, name: "Kitchen Countertop Slab") }

  # A subcategory left active under a deactivated parent must be hidden too.
  let!(:subcategory) { create(:category, name: "Kitchen Sinks", parent: disabled_category, is_active: true) }
  let!(:hidden_sub_product) { create(:product, category: subcategory, name: "Kitchen Double Bowl Sink") }

  describe "search results" do
    it "excludes products from a deactivated category" do
      get search_path, params: { q: "Kitchen" }

      expect(response.body).not_to include(hidden_product.name)
      expect(response.body).not_to include(hidden_sub_product.name)
    end

    it "still returns products from active categories" do
      get search_path, params: { q: "Tile" }
      expect(response.body).to include(live_product.name)
    end
  end

  describe "search suggestions" do
    it "excludes hidden products and the deactivated category" do
      get search_suggestions_path, params: { q: "Kitchen" }

      expect(response.body).not_to include(hidden_product.name)
      expect(response.body).not_to include(hidden_sub_product.name)
      expect(response.body).to include("No matches")
    end
  end

  describe "product pages" do
    it "404s for a product in a deactivated category" do
      get product_path(hidden_product)
      expect(response).to have_http_status(:not_found)
    end

    it "404s for a product under a deactivated parent category" do
      get product_path(hidden_sub_product)
      expect(response).to have_http_status(:not_found)
    end

    it "still serves products in active categories" do
      get product_path(live_product)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "category pages" do
    it "404s for the deactivated category" do
      get category_path(disabled_category)
      expect(response).to have_http_status(:not_found)
    end

    it "404s for an active subcategory of a deactivated parent" do
      get category_path(subcategory)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "home page and navigation" do
    it "does not list products from deactivated categories" do
      get root_path

      expect(response.body).not_to include(hidden_product.name)
      expect(response.body).not_to include(hidden_sub_product.name)
    end

    it "does not link to the deactivated category anywhere" do
      get root_path

      expect(response.body).not_to include(category_path(disabled_category))
      expect(response.body).not_to include(category_path(subcategory))
      expect(response.body).to include(category_path(live_category))
    end
  end

  describe "adding to cart" do
    it "refuses a product in a deactivated category" do
      sign_in create(:user)

      post add_item_cart_path, params: { product_id: hidden_product.id }

      expect(response).to have_http_status(:not_found)
    end
  end
end
