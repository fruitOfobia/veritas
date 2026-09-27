class CreateProductReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    add_index :product_reviews, [:product_id, :user_id], unique: true
  end
end
