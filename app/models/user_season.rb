class UserSeason < ActiveRecord::Base
  # attr_accessible :approved, :season_id, :user_id
  belongs_to :user
  belongs_to :season

  def is_approved?
  	if approved
  		return approved
  	else
  		return false
  	end
  end

  def self.user_ids_in_current_season
  	where(season_id: Season.current_season).pluck(:user_id)
  end
end
