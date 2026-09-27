require "rails_helper"

RSpec.describe "Storefront visibility scopes", type: :model do
  let!(:live_category) { create(:category, is_active: true) }
  let!(:live_product) { create(:product, category: live_category) }

  let!(:disabled_category) { create(:category, is_active: false) }
  let!(:hidden_product) { create(:product, category: disabled_category) }

  let!(:subcategory) { create(:category, parent: disabled_category, is_active: true) }
  let!(:hidden_sub_product) { create(:product, category: subcategory) }

  describe "Product.visible" do
    it "includes products in an active top-level category" do
      expect(Product.visible).to include(live_product)
    end

    it "excludes products in a deactivated category" do
      expect(Product.visible).not_to include(hidden_product)
    end

    it "excludes products in an active subcategory of a deactivated parent" do
      expect(Product.visible).not_to include(hidden_sub_product)
    end

    it "excludes products that are themselves inactive" do
      inactive = create(:product, category: live_category, is_active: false)
      expect(Product.visible).not_to include(inactive)
    end
  end

  describe "Category.visible" do
    it "includes an active top-level category" do
      expect(Category.visible).to include(live_category)
    end

    it "excludes a deactivated category" do
      expect(Category.visible).not_to include(disabled_category)
    end

    it "excludes an active subcategory of a deactivated parent" do
      expect(Category.visible).not_to include(subcategory)
    end
  end
end
