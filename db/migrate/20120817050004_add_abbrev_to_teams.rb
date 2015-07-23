class AddAbbrevToTeams < ActiveRecord::Migration
  def change
    add_column :teams, :short_city_name, :string
  end
end
