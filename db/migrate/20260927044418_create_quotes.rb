class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :quote_number, null: false
      t.integer :status, null: false, default: 0
      t.string :company_name
      t.text :notes
      t.text :admin_notes
      t.datetime :quoted_at
      t.datetime :responded_at

      t.timestamps
    end

    add_index :quotes, :quote_number, unique: true
  end
end
