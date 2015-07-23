class Season < ActiveRecord::Base
  # attr_accessible :signup_status, :year
  has_many :user_seasons
  has_many :weeks

  def self.current_season
    return Season.where(year: (Time.now-1.month).year).last
  	# Season.where(:signup_status => 2).order("year asc").last
  end

  def self.next_season
  	Season.where(:signup_status => 1).last
  end

  def self.season_accepting_signups
    where(signup_status: 1).first
  end

  def weeks
    Week.where(season_id: id)
  end

  def has_had_a_closed_week?
    weeks.where(closed: true).count > 0
  end

  def approved_user_ids
    user_seasons.where(approved: true).pluck(:user_id)
  end

  def self.do_work
  	# make season 2012 and season 2013 if they don't already exist
  	Season.where(year: 2012).first_or_create!
  	Season.where(year: 2013).first_or_create!
  	# give everyone who is currently approved a user_season entry with Season.find_by_season_year(2012), if they don't already have it
  	season_2012 = Season.where(year: 2012).first
  	User.where(approved: true).each do |x|
  		UserSeason.where(season_id: season_2012.id, user_id: x.id, approved: true).first_or_create!
  	end
  	# add Season.find_by_Season_year(2012) to all currently existing weeks
    Week.where(:season_id => nil).each do |y|
      y.update_attribute(:season_id, Season.where(:year => 2012).first.id)
    end
  	# add the 2012 season_id to all currently existing games
    Game.where(:season_id => nil).each do |y|
      y.update_attribute(:season_id, Season.where(:year => 2012).first.id)
    end
  	# DONE add a banner at the top of SIHP for users without a 2013 user_season, with a button to declare their intent

  	# DONE make it so that all new signups get a user_season entry for 2013

  	# change status declaration to take into account only games in current season, but make sure they have a user_season for the current season
  end
end
