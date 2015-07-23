class AddSeasonYearToGameAndWeek < ActiveRecord::Migration
  def change
  	add_column :weeks, :season_id, :integer
  	add_column :games, :season_id, :integer 
  end
end
