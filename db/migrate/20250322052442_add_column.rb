class AddColumn < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_id, :string
  end
end
