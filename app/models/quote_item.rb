class QuoteItem < ApplicationRecord
  belongs_to :quote
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :quote_id, message: "is already on this quote" }

  def total_quoted_price
    return nil if quoted_unit_price.blank?

    quoted_unit_price * quantity
  end
end
