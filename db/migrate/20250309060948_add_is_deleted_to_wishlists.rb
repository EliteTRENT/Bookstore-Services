class AddIsDeletedToWishlists < ActiveRecord::Migration[8.0]
  def change
    add_column :wishlists, :is_deleted, :boolean, default: false
  end
end
