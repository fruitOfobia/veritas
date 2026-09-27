class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :sku, null: false
      t.text :description
      t.jsonb :specifications, default: {}, null: false
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :mrp, precision: 12, scale: 2
      t.integer :stock, default: 0, null: false
      t.string :unit, default: "unit", null: false
      t.boolean :is_active, default: true, null: false
      t.boolean :is_featured, default: false, null: false

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :is_featured
  end
end
