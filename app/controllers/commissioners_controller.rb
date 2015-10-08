class CommissionersController < ApplicationController
	before_filter :ensure_admin
  def index
    #@unverified_users = User.where(verified: false)
  	#@users = User.where("id in (?)",UserSeason.user_ids_in_current_season).includes(:user_seasons).order(:id).all
    #@teams = Team.order(:id).all
    @picks_week = Week.order(:id).last
    @weeks = (Week.where(:closed => false) + Week.where(:closed => true).order("id DESC").limit(1)).sort_by{|x| [x.season_id, x.week_number]}
    @seasons = Season.order(:id).all
  end

  def users
    @picks_week = Week.order(:id).last
    @unverified_users = User.where(verified: false)
    @users = User.where("id in (?)",UserSeason.user_ids_in_current_season).includes(:user_seasons).order(:id).all
  end

  def approve
  	logger.debug params[:approve_id]
  	User.find(params[:approve_id]).update_attribute(:approved, true)
  	render :text => "success"
  	
  end

  def approve_user_season
    logger.debug params[:user_season_approve_id]
    UserSeason.find(params[:user_season_approve_id]).update_attribute(:approved, true)
    render :text => "success"
  end

  def verify_user
    logger.debug params[:user_verify_id]
    User.find(params[:user_verify_id]).update_attribute(:verified,true)
    User.find(params[:user_verify_id]).generate_referral_code!
    render :text => "success"
  end


  def review
    @week = Week.find(params[:week_id])
    
    @primary_picks = @week.primary_picks.includes([:user]).sort_by{|x| [x.team.short_city_name, x.user.full_name]}

    @primary_freq = {}
    @primary_picks.each do |pick|
      if !@primary_freq.has_key?(pick.team.mascot)
        @primary_freq[pick.team.mascot] = [pick.team.short_city_name, 0]
      end
      @primary_freq[pick.team.mascot][1] += 1
    end
    @primary_freq = @primary_freq.sort_by {|k,v| v[1]}.reverse.to_h

    @users_who_havent_picked_emails = (@week.user_ids_who_can_pick_in_primary_pool - @primary_picks.collect{|x| x.user_id}).collect{|y| User.find(y).email}
    
    if @week.has_second_chance_started?
      @secondary_picks = @week.secondary_picks.includes([:user]).sort_by{|x| [x.team.short_city_name, x.user.full_name]}
      
      @secondary_freq = {}
      @secondary_picks.each do |pick|
        if !@secondary_freq.has_key?(pick.team.mascot)
          @secondary_freq[pick.team.mascot] = [pick.team.short_city_name, 0]
        end
        @secondary_freq[pick.team.mascot][1] += 1
      end
      @secondary_freq = @secondary_freq.sort_by {|k,v| v[1]}.reverse.to_h
      
      @second_users_who_havent_picked_emails = (@week.user_ids_who_can_pick_in_secondary_pool - @secondary_picks.collect{|x| x.user_id}).collect{|y| User.find(y).email}
    end 
    respond_to do |format|
      format.html
    end
    
  end

  def ensure_admin
  	if current_user.try(:is_admin) != 1
  		redirect_to root_path, error: "you are not an admin"
  		return
  	end
  end
end
