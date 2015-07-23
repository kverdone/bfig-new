class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :city
      t.string :mascot
      t.string :background_color
      t.string :text_color

      t.timestamps
    end
  end
end
