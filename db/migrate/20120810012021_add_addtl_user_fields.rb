class AddAddtlUserFields < ActiveRecord::Migration
  def change
    add_column :users, :is_admin, :integer
    add_column :users, :is_veteran, :integer
  end
end
