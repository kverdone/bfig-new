class CreateUserSeasons < ActiveRecord::Migration
  def change
    create_table :user_seasons do |t|
      t.integer :user_id
      t.integer :season_id
      t.boolean :approved

      t.timestamps
    end
  end
end
