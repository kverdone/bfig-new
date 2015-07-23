class CreateSeasons < ActiveRecord::Migration
  def change
    create_table :seasons do |t|
      t.integer :year
      t.integer :signup_status

      t.timestamps
    end
  end
end
