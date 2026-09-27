require "rails_helper"

RSpec.describe "Search suggestions", type: :request do
  let!(:category) { create(:category, name: "Flooring") }
  let!(:product) { create(:product, category: category, name: "Vitrified Floor Tile") }

  it "returns nothing for a too-short query" do
    get search_suggestions_path, params: { q: "t" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Keep typing")
  end

  it "returns matching products and categories" do
    get search_suggestions_path, params: { q: "floor" }

    expect(response.body).to include(product.name)
    expect(response.body).to include(category.name)
  end

  it "shows a no-matches message for an unmatched query" do
    get search_suggestions_path, params: { q: "zzzznomatch" }

    expect(response.body).to include("No matches")
  end

  describe "product picker options (quote form)" do
    it "returns matching products as JSON" do
      get product_options_path, params: { q: "floor" }

      body = response.parsed_body
      expect(response).to have_http_status(:ok)
      expect(body.map { |p| p["name"] }).to include(product.name)
      expect(body.first).to include("id", "name", "category", "price", "unit")
    end

    it "returns a starter list when no query is given" do
      get product_options_path

      expect(response.parsed_body.map { |p| p["name"] }).to include(product.name)
    end

    it "excludes products whose category is deactivated" do
      hidden_category = create(:category, name: "Kitchen", is_active: false)
      hidden = create(:product, category: hidden_category, name: "Kitchen Sink Unit")

      get product_options_path, params: { q: "Kitchen" }

      expect(response.parsed_body.map { |p| p["name"] }).not_to include(hidden.name)
    end
  end
end
