require "rails_helper"

RSpec.describe "Cart", type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product, price: 200, stock: 10) }

  before { sign_in user }

  it "adds a product to the cart" do
    post add_item_cart_path, params: { product_id: product.id, quantity: 2 }, headers: { "HTTP_REFERER" => cart_url }

    expect(response).to redirect_to(cart_path)
    expect(user.cart.reload.total_items).to eq(2)
  end

  it "accumulates quantity when the same product is added again" do
    post add_item_cart_path, params: { product_id: product.id, quantity: 1 }
    post add_item_cart_path, params: { product_id: product.id, quantity: 3 }

    expect(user.cart.reload.cart_items.sole.quantity).to eq(4)
  end

  it "removes the line item when quantity is updated to zero" do
    item = user.cart.add_product(product, quantity: 2)

    patch update_item_cart_path(item_id: item.id), params: { quantity: 0 }

    expect(user.cart.reload.cart_items).to be_empty
  end

  it "removes an item from the cart" do
    item = user.cart.add_product(product, quantity: 1)

    delete remove_item_cart_path(item_id: item.id)

    expect(user.cart.reload.cart_items).to be_empty
  end

  it "redirects anonymous visitors to sign in" do
    sign_out user
    get cart_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
