class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.references :address, null: false, foreign_key: true
      t.integer :quantity
      t.decimal :price_at_purchase
      t.string :status
      t.decimal :total_price

      t.timestamps
    end
  end
end
