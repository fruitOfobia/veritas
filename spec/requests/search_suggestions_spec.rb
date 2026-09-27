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
end
