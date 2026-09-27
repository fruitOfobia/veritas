require "rails_helper"

RSpec.describe Quote, type: :model do
  it "generates a unique quote_number on create" do
    quote = create(:quote)
    expect(quote.quote_number).to start_with("QT")
  end

  it "builds line items via nested attributes" do
    user = create(:user)
    product = create(:product)

    quote = Quote.new(user: user, quote_items_attributes: [ { product_id: product.id, quantity: 3 } ])

    expect(quote.save).to be true
    expect(quote.quote_items.size).to eq(1)
    expect(quote.quote_items.first.quantity).to eq(3)
  end

  describe "duplicate products" do
    let(:user) { create(:user) }
    let(:product) { create(:product, name: "Vitrified Floor Tile") }

    it "rejects the same product listed twice in one submission" do
      quote = Quote.new(user: user, quote_items_attributes: [
        { product_id: product.id, quantity: 5 },
        { product_id: product.id, quantity: 3 }
      ])

      expect(quote).not_to be_valid
      expect(quote.errors.full_messages.join).to include("only be added once", product.name)
    end

    it "rejects adding a product already on a saved quote" do
      quote = create(:quote, user: user)
      quote.quote_items.destroy_all
      create(:quote_item, quote: quote, product: product)

      duplicate = QuoteItem.new(quote: quote, product: product, quantity: 1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id].join).to include("already on this quote")
    end

    it "allows different products on the same quote" do
      quote = Quote.new(user: user, quote_items_attributes: [
        { product_id: product.id, quantity: 5 },
        { product_id: create(:product).id, quantity: 3 }
      ])

      expect(quote).to be_valid
    end
  end

  describe "#fully_quoted? and #total_quoted_amount" do
    it "is false until every line item has a price, then sums correctly" do
      quote = create(:quote)
      quote.quote_items.destroy_all
      item1 = create(:quote_item, quote: quote, product: create(:product), quantity: 2, quoted_unit_price: nil)
      item2 = create(:quote_item, quote: quote, product: create(:product), quantity: 3, quoted_unit_price: nil)

      expect(quote.reload.fully_quoted?).to be false

      item1.update!(quoted_unit_price: 100)
      item2.update!(quoted_unit_price: 50)

      expect(quote.reload.fully_quoted?).to be true
      expect(quote.total_quoted_amount).to eq(2 * 100 + 3 * 50)
    end
  end
end
