class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.string :razorpay_order_id
      t.string :razorpay_payment_id
      t.string :razorpay_signature
      t.datetime :paid_at

      t.timestamps
    end
  end
end
