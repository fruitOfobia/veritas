class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.integer :discount_type, null: false, default: 0
      t.decimal :discount_value, precision: 12, scale: 2, null: false
      t.decimal :min_order_amount, precision: 12, scale: 2, default: 0
      t.decimal :max_discount_amount, precision: 12, scale: 2
      t.integer :usage_limit
      t.integer :used_count, default: 0, null: false
      t.datetime :valid_from
      t.datetime :valid_until
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end

    add_index :coupons, :code, unique: true
  end
end
