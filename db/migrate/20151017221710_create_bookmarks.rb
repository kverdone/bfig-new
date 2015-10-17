class CreateBookmarks < ActiveRecord::Migration
  def change
    create_table :bookmarks do |t|
      t.integer :pick_id

      t.timestamps
    end
  end
end
