class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :label, default: "Home"
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :pincode, null: false
      t.string :landmark
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end
  end
end
