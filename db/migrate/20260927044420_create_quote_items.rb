class CreateQuoteItems < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.text :notes
      t.decimal :quoted_unit_price, precision: 12, scale: 2

      t.timestamps
    end
  end
end
