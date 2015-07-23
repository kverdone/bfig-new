class CreatePicks < ActiveRecord::Migration
  def change
    create_table :picks do |t|
      t.integer :user_id, :null => false
      t.integer :team_id, :null => false
      t.integer :week_id, :null => false
      t.text :why_pick
      t.text :comment

      t.timestamps
    end
  end
end
