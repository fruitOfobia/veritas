require "rails_helper"

RSpec.describe "Checkout", type: :request do
  let(:user) { create(:user) }
  let(:address) { create(:address, user: user) }
  let(:product) { create(:product, price: 150, stock: 10) }

  before do
    sign_in user
    user.cart.add_product(product, quantity: 2)
  end

  it "redirects to the cart when the cart is empty" do
    user.cart.cart_items.destroy_all
    get new_order_path
    expect(response).to redirect_to(cart_path)
  end

  it "places an order from the cart and empties it" do
    post orders_path, params: { order: { address_id: address.id, payment_method: "cod" } }

    order = user.orders.last
    expect(response).to redirect_to(order_path(order))
    expect(order.total).to eq(300)
    expect(order.order_items.sole.quantity).to eq(2)
    expect(user.cart.reload.cart_items).to be_empty
  end

  it "applies a valid coupon's discount to the order total" do
    coupon = create(:coupon, code: "SAVE50", discount_type: :fixed, discount_value: 50, min_order_amount: 0)

    post orders_path, params: { order: { address_id: address.id, payment_method: "cod", coupon_code: coupon.code } }

    order = user.orders.last
    expect(order.discount_amount).to eq(50)
    expect(order.total).to eq(250)
  end

  it "lets a customer cancel a cancellable order" do
    order = create(:order, user: user, address: address, status: :pending)

    post cancel_order_path(order)

    expect(order.reload).to be_cancelled
  end
end
