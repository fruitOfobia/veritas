class AddUniqueIndexToQuoteItems < ActiveRecord::Migration[8.1]
  def up
    # Collapse any pre-existing duplicates before the index can enforce this:
    # keep the earliest row per (quote, product) and fold the others' quantity
    # into it, so no requested quantity is silently lost.
    duplicates = execute(<<~SQL).to_a
      SELECT quote_id, product_id
      FROM quote_items
      GROUP BY quote_id, product_id
      HAVING COUNT(*) > 1
    SQL

    duplicates.each do |row|
      items = QuoteItem.where(quote_id: row["quote_id"], product_id: row["product_id"]).order(:id).to_a
      keeper = items.shift
      keeper.update_columns(quantity: items.sum(&:quantity) + keeper.quantity)
      QuoteItem.where(id: items.map(&:id)).delete_all
    end

    add_index :quote_items, [ :quote_id, :product_id ], unique: true
  end

  def down
    remove_index :quote_items, [ :quote_id, :product_id ]
  end
end
