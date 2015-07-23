class AddIsSecondChancePickToPicks < ActiveRecord::Migration
  def change
  	add_column :picks, :is_second_chance, :boolean
  end
end
