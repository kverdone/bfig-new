class UserSeasonsController < ApplicationController
  before_filter :authenticate_user!

  def referrals
    # get rookies who were referred
    referred_rookies = User.where.not(referring_user_id: nil).select{|x| x.is_rookie? == true}
    paid_referred_rookies = referred_rookies.select{|x| x.user_seasons.first.approved == true}

    # build a hash with key=referring_user_id and value=number_of_referrals
    rookie_referral_count = referred_rookies.collect{|z| z.referring_user_id}.each_with_object(Hash.new(0)) {|e, h| h[e] += 1}
    paid_rookie_referral_count = paid_referred_rookies.collect{|z| z.referring_user_id}.each_with_object(Hash.new(0)) {|e, h| h[e] += 1}

    # get all user_ids who have a referral
    referring_users = User.where(id: rookie_referral_count.keys)

    @data = []

    # build the array of data
    referring_users.each do |user|
      d = {}
      d[:full_name] = user.full_name
      rookie_referral_count.has_key?(user.id) ? d[:total_referral_count] = rookie_referral_count[user.id] : d[:total_referral_count] = 0
      paid_rookie_referral_count.has_key?(user.id) ? d[:paid_referral_count] = paid_rookie_referral_count[user.id] : d[:paid_referral_count] = 0
      @data << d
    end

    @data.sort_by!{ |k| -k[:total_referral_count] }
  end

  def new
  end

  def create
  	season = Season.season_accepting_signups

  	redirect_to :root if !current_user || !season

  	user = current_user

  	UserSeason.where(user_id: user.id, season_id: season.id).first_or_create!
  	# @user_season = UserSeason.new
  	# @user_season.user_id = user.id
  	# @user_season.season_id = season.id
  	# @user_season.save
  	redirect_to :root

  end
end
