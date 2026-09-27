class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.references :coupon, null: true, foreign_key: true
      t.string :order_number, null: false
      t.integer :status, null: false, default: 0
      t.integer :payment_method, null: false, default: 0
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :shipping_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.text :notes
      t.datetime :placed_at

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
  end
end
