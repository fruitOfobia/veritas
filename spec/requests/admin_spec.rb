require "rails_helper"

RSpec.describe "Admin area", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:customer) { create(:user) }
  let!(:category) { create(:category, name: "Kitchen") }
  let!(:product) { create(:product, category: category, name: "Quartz Countertop") }

  describe "authorization" do
    it "lets an admin in" do
      sign_in admin
      get admin_root_path
      expect(response).to have_http_status(:ok)
    end

    it "turns a signed-in customer away" do
      sign_in customer
      get admin_root_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("not authorized")
    end

    it "sends an anonymous visitor to sign in" do
      get admin_root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "categories" do
    before { sign_in admin }

    # Category#to_param is the slug, so generated admin links look like
    # /admin/categories/kitchen/edit rather than /admin/categories/1/edit.
    it "edits a category looked up by slug" do
      get edit_admin_category_path(category)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(category.name)
    end

    it "still accepts a numeric id" do
      get edit_admin_category_path(category.id)
      expect(response).to have_http_status(:ok)
    end

    it "updates a category" do
      patch admin_category_path(category), params: { category: { name: "Kitchens" } }

      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.name).to eq("Kitchens")
    end

    it "deletes a category" do
      expect { delete admin_category_path(category) }.to change(Category, :count).by(-1)
    end
  end

  describe "products" do
    before { sign_in admin }

    it "edits a product looked up by slug" do
      get edit_admin_product_path(product)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
    end

    it "updates a product" do
      patch admin_product_path(product), params: { product: { price: 999 } }

      expect(response).to redirect_to(admin_products_path)
      expect(product.reload.price).to eq(999)
    end

    it "deletes a product" do
      expect { delete admin_product_path(product) }.to change(Product, :count).by(-1)
    end
  end
end
