class AddSecondTeamIdToPick < ActiveRecord::Migration
  def change
    add_column :picks, :second_team_id, :integer
  end
end
