class AddOpenAndClosedToWeeks < ActiveRecord::Migration
  def change
    add_column :weeks, :open, :boolean, :default => false
    add_column :weeks, :closed, :boolean, :default => false
  end
end
