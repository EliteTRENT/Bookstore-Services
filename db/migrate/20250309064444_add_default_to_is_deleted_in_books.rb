class AddDefaultToIsDeletedInBooks < ActiveRecord::Migration[8.0]
  def change
    change_column_default :books, :is_deleted, false
  end
end
