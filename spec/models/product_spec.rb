require "rails_helper"

RSpec.describe Product, type: :model do
  it "is valid with a name, category, sku and non-negative price/stock" do
    expect(build(:product)).to be_valid
  end

  it "requires a unique sku" do
    create(:product, sku: "SKU-1")
    duplicate = build(:product, sku: "SKU-1")
    expect(duplicate).not_to be_valid
  end

  it "auto-generates a slug from the name when blank" do
    product = create(:product, name: "Quartz Countertop", slug: nil)
    expect(product.slug).to eq("quartz-countertop")
  end

  it "computes discount_percent and on_sale? from price vs mrp" do
    on_sale = build(:product, price: 80, mrp: 100)
    not_on_sale = build(:product, price: 100, mrp: nil)

    expect(on_sale.discount_percent).to eq(20)
    expect(on_sale).to be_on_sale
    expect(not_on_sale).not_to be_on_sale
  end

  it "reports in_stock? based on stock quantity" do
    expect(build(:product, stock: 0)).not_to be_in_stock
    expect(build(:product, stock: 5)).to be_in_stock
  end

  describe ".search" do
    it "matches on name or description, and returns all when blank" do
      matching = create(:product, name: "Ceramic Tile")
      other = create(:product, name: "Steel Rod")

      expect(Product.search("ceramic")).to contain_exactly(matching)
      expect(Product.search(nil)).to include(matching, other)
    end
  end
end
