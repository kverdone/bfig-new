class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :full_name, :password, :password_confirmation, :remember_me, :referred_by

  has_many :picks
  has_many :user_seasons

  validates :email, :uniqueness => { :case_sensitive => false }
  validates :full_name, :presence => true
  validates :signup_referral_code, :presence => true, on: :create

  before_create :check_for_referral
  after_create :sign_up_for_season
  after_create :generate_referral_code_for_verified_users

  def check_for_referral
    referring_user = User.where(referral_code: self.signup_referral_code.upcase).first
    self.verified = referring_user.present?
    self.referring_user_id = referring_user.id if referring_user
  end

  def referring_user
    referring_user_id ? User.find(referring_user_id) : User.new
  end

  def is_rookie?
    user_seasons.count == 1
  end

  # next line should be Season.season_accepting_signups.id, but Peter wants to create signups from the console after the season is closed
  def sign_up_for_season
    if Season.season_accepting_signups
      UserSeason.create(season_id: Season.season_accepting_signups.id, user_id: id)  
    else
      UserSeason.create(season_id: Season.current_season.id, user_id: id)  
    end
  end

  def generate_referral_code_for_verified_users
    generate_referral_code! if verified
  end

  def self.alive_primary_pool_users
    User.all.select{|x| x.status == 1}
  end


  def self.alive_secondary_pool_users
    User.all.select{|x| x.status == 2}
  end

  def self.grouped_by_status
    User.all.group_by{|x| x.status}
  end

  def self.group_user_ids_by_status(user_ids)
    where("id IN (?)", user_ids).group_by{|x| x.status}
  end

  # Public: Determines the user's status
  #
  # Possible Return Values
  #   0 - signed-up, awaiting approval
  #   1 - alive in primary pool
  # => All of the user's primary picks are winners
  #   2 - alive in second-chance pool
  # => If before second_chance has started, these are users who lost in the primary pool. If
  #     after second_chance has started, these are users who have all winning second_chance picks
  #   3 - knocked out for the season
  # => These users have either lost in the primary pool after second_chance started, or 
  #     lost in the second_chance pool
  def status
    return 0 unless has_been_approved_for_this_season?
    return 1 if all_primary_picks_are_wins?
    if first_loss_before_second_chance_start? && all_secondary_picks_are_wins?
      return 2
    end
    if first_loss_before_second_chance_start? == false || all_secondary_picks_are_wins? == false
      return 3
    end
    raise "error determining status"
  end

  def first_loss_before_second_chance_start?
    primary_losing_week_number < Week.second_chance_week_number_start
  end

  def has_been_approved_for_this_season?
    user_season_record = UserSeason.where(user_id: self.id, season_id: Season.current_season).first
    user_season_record ? user_season_record.is_approved? : false
  end

  # Public: Provides a string that describes the user's status on the frontend
  #
  # Returns status string for display on the SIHP
  def status_in_words
    return "Alive" if status == 1
    return "Knocked Out (Second Chance)" if status == 2
    return "Knocked Out for the season!"
  end

  def primary_losing_week_number
    losing_pick = self.primary_pool_picks.select{|pck| pck.is_game_over? && !pck.is_a_winner?}.first
    return losing_pick.blank? ? -1 : Week.find(losing_pick.week_id).week_number
  end

  # Public: Checks if all of a user's primary pool picks are winners
  #
  # Returns false if the number of primary picks is less than the number
  #   of closed primary picking weeks (i.e. they missed a pick)
  # Returns true if none of the user's picks to completed games are losers
  def all_primary_picks_are_wins?
    user_picks = primary_pool_picks
    return false if user_picks.count < Week.closed_week_ids.count
    return user_picks.select{|x| x.is_game_over? && !x.is_a_winner? }.count == 0
  end

  # Public: Checks if all of a user's second chance pool picks are winners
  #
  # Returns false if the number of second chance picks is less than the number
  #   of closed second_chance picking weeks (i.e. they missed a pick)
  # Returns true if none of the user's picks to completed games are losers
  def all_secondary_picks_are_wins?
    user_picks = secondary_pool_picks
    return false if user_picks.count < Week.closed_second_chance_pick_week_ids.count
    return user_picks.select{|x| x.is_game_over? }.select{|y| !y.is_a_winner? }.count == 0
  end

  # Public: Gets all primary pool picks in closed weeks for the user that called the method
  #
  # Returns an array of picks, ordered by week_id
  def primary_pool_picks
    picks.where(:week_id => Week.closed_week_ids).where(:is_second_chance => nil).order(:week_id)
  end

  def primary_picks_up_to_week_id(week_id)
    available_week_ids = Week.closed_week_ids.select{|x| x <= week_id}
    picks.where(:is_second_chance => nil).where("week_id IN (?)", available_week_ids).order(:week_id)
  end

  # Public: Gets all secondary pool picks in closed weeks for the user that called the method
  #
  # Returns an array of picks, ordered by week_id
  def secondary_pool_picks
    picks.where(:week_id => Week.closed_week_ids).where(:is_second_chance => true).order(:week_id)
  end

  # Public: Gets a list of team_ids that the user may not pick again. If the user is still in 
  # the primary pool, it simply plucks the team_id from their picks. If the user is in the 
  # secondary pool, it plucks the team_id from their secondary picks, as well as any second_team_id's
  #
  # Returns an array of team_id's
  def team_ids_the_user_cant_pick
    return primary_pool_picks.pluck(:team_id) || [] if status == 1
    return secondary_pool_picks.pluck(:team_id) + secondary_pool_picks.where("second_team_id IS NOT NULL").pluck(:second_team_id) || [] if status == 2
  end

  def could_sign_up_for_another_season?
    Season.season_accepting_signups.present? && UserSeason.where(user_id: id, season_id: Season.season_accepting_signups).blank?
  end

  def is_signed_up_for_next_season?
    UserSeason.where(user_id: id, season_id: Season.season_accepting_signups).present?
  end

  def is_signed_up_for_current_season?
    UserSeason.where(user_id: id, season_id: Season.current_season).present?
  end

  def array_of_picks_with_team_info
    primary_pool_picks.select(:team_id).collect{|x| Team.select(:short_city_name).find(x.team_id) }
  end

  def secondary_array_of_picks_with_team_info
    secondary_pool_picks.select(:team_id).collect{|x| Team.select(:short_city_name).find(x.team_id) }
  end

  def array_of_double_picks_with_team_info
    secondary_pool_picks.where("second_team_id IS NOT NULL").select(:second_team_id).collect{|x| Team.select(:short_city_name, :text_color, :background_color).find(x.second_team_id) }
  end

  # cleanup in preparation for referral codes. destroying users who signed up but never played in a season
  def self.destroy_unparticipating_users!
    users = User.select(:id,:email,:created_at,:approved).all.select{|x| x.user_seasons.where(approved: true).count == 0}
    string = "DESTROYING #{users.count} UNPARTICIPATING USERS"
    users.each{|u| u.destroy}
    return string
  end

  # generate a random 6 char referral code for a user, ensuring uniqueness
  def generate_referral_code!
    ref_code = ''
    existing_referral_codes = User.pluck(:referral_code)
    while existing_referral_codes.include?(ref_code) && ref_code == ''
      ref_code = ''
      ref_code << Team.pluck(:short_city_name).sample
      # 3.times do
        # ref_code << ('a'..'z').to_a.sample
      # end
      4.times do
        ref_code << ('0'..'9').to_a.sample
      end  
    end
    self.update_attribute(:referral_code, ref_code)
  end
end
