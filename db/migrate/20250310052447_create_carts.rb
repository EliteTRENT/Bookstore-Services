class CreateCarts < ActiveRecord::Migration[7.0]
  def change
    create_table :carts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.boolean :is_deleted, null: false, default: false

      t.timestamps
    end
  end
end
