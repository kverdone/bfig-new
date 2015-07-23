class AddSomeIndexes < ActiveRecord::Migration
  def change
  	add_index :picks, :user_id
  end
end
