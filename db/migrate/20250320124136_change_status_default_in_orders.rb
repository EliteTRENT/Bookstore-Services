class ChangeStatusDefaultInOrders < ActiveRecord::Migration[8.0]
  def change
    change_column :orders, :status, :string, default: 'pending', null: false
  end
end
