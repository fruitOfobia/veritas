require "rails_helper"

RSpec.describe "Quotes", type: :request do
  let(:user) { create(:user) }
  let(:product) { create(:product) }

  before { sign_in user }

  it "renders a searchable product picker on the quote form" do
    get new_quote_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('data-controller="product-picker"')
    expect(response.body).to include("Search products by name")
  end

  it "prefills the picker when starting a quote from a product page" do
    get new_quote_path, params: { product_id: product.id }

    expect(response.body).to include(product.name)
  end

  it "submits a new quote request with line items" do
    expect {
      post quotes_path, params: {
        quote: {
          company_name: "Acme Interiors",
          notes: "Need this by next month",
          quote_items_attributes: { "0" => { product_id: product.id, quantity: 25 } }
        }
      }
    }.to change(Quote, :count).by(1)

    quote = user.quotes.last
    expect(response).to redirect_to(quote_path(quote))
    expect(quote).to be_pending
    expect(quote.quote_items.sole.quantity).to eq(25)
  end

  it "refuses a quote listing the same product twice" do
    expect {
      post quotes_path, params: {
        quote: {
          quote_items_attributes: {
            "0" => { product_id: product.id, quantity: 5 },
            "1" => { product_id: product.id, quantity: 2 }
          }
        }
      }
    }.not_to change(Quote, :count)

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("only be added once")
  end

  it "lets the customer accept a fully-quoted request and creates an order" do
    address = create(:address, user: user)
    quote = create(:quote, user: user, status: :quoted)
    quote.quote_items.destroy_all
    create(:quote_item, quote: quote, product: product, quantity: 4, quoted_unit_price: 200)

    expect {
      post accept_quote_path(quote)
    }.to change(Order, :count).by(1)

    expect(quote.reload).to be_accepted
    order = user.orders.last
    expect(order.total).to eq(800)
    expect(order.address).to eq(address)
  end

  it "does not let a customer accept a quote that isn't fully priced yet" do
    quote = create(:quote, user: user, status: :quoted)
    create(:quote_item, quote: quote, product: product, quantity: 1, quoted_unit_price: nil)

    post accept_quote_path(quote)

    expect(quote.reload).to be_quoted
  end

  it "prevents a customer from viewing another customer's quote" do
    other_quote = create(:quote, user: create(:user))

    get quote_path(other_quote)

    expect(response).to have_http_status(:not_found)
  end
end
