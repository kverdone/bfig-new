class PicksController < ApplicationController
  before_filter :authenticate_user!, :except => [:overview]

  # This is the big daddy method that describes the signed-in homepage behavior
  # 
  # The picking page view template can be found in app/views/picks/new.html.erb
  def overview
    # display SOHP if not signed in
    return respond_to :html if !current_user

    if Week.closed_week_ids.count == 0 && !Week.current_pick_week
      render 'loggedin' 
      return
    end

    # if there is at least one closed week, and the user is approved, and there is no open week, redirect to spreadsheet
    if current_user.has_been_approved_for_this_season? && Week.closed_week_ids.count > 0 && !Week.current_pick_week
      redirect_to :action => "spreadsheet"
      return
    end

    # if the user is alive in primary pool, OR user is alive in secondary pool and second_chance has started, prepare for picking
    if current_user.status == 1 && Week.current_pick_week || (current_user.status == 2 && Week.has_second_chance_started?)
      @week = Week.current_pick_week
      @existing_pick = Pick.where(:week_id => @week, :user_id => current_user.id).first
      @pick = Pick.new
      @games = Game.where(:week_number => @week.week_number, :season_id => @week.season_id).order(:id)
      @team_ids_the_user_cant_pick = current_user.team_ids_the_user_cant_pick
      render "new"
      return
    end

    # if the user is out in primary pool, and second chance hasn't started, display "knocked out stuff"
    if current_user.status == 2 && !Week.has_second_chance_started?
        render "new"
        return
    end

    # if the user is completely knocked out, render a blank pick page
    if current_user.status == 3
      render "new"
      return
    end

    if current_user
      render 'loggedin' 
      return
    end
    respond_to do |format|
      format.html
    end
  end

  def pick
    respond_to do |format|
      format.html
    end
  end

  def spreadsheet
    @number_of_picks_in_week = Pick.where(is_second_chance: nil, week_id: Week.last_closed_week_id).count
    @most_popular_picks = Pick.weekly_stats
    @week = Week.last_closed_week
    if Week.has_second_chance_started?
      @second_chance_data =  Rails.cache.read('secondary_spreadsheet_data')
    end

    @data = @week.calc_spread
    render 'spreadsheet_new'

  #  if ENV["SHOULD_USE_NEW_SPREADSHEET"] == true
  #    @data = @week.calc_spread
  #    render 'spreadsheet_new'
  #  else
  #    @data = Rails.cache.read('primary_spreadsheet_data')
  #    render 'spreadsheet'
  #  end
  end

  def week
    logger.debug params["week_number"]
    @games = []
    Game.where(:week_number => params["week_number"].to_i).each do |game|
      @games << game
    end
    while @games.count < 17
      @games << Game.new
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def create_week
    logger.debug params.inspect
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def make
    # redirect to weeks/1/pick for current week
    redirect_to "/weeks/#{Week.current_pick_week.week_number}/pick"
  end

  def history
    render 'history' 
  end
  
  def tree
    render 'tree'
  end
  
  def tree_radial
    render 'tree_radial'
  end
  
  def tree_vertical
    render 'tree_vertical'
  end
  
  def tree_elbow
    render 'tree_elbow'
  end


  def rules
    render 'rules'
  end
  # GET /picks
  # GET /picks.json
  def index
    # @picks = Pick.all
    @picks = current_user.picks

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @picks }
    end
  end

  # GET /picks/1
  # GET /picks/1.json
  def show
    @pick = Pick.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @pick }
    end
  end

  # GET /picks/new
  # GET /picks/new.json
  def new
    # THIS ISNT USED NOW
    # RENDERING THE TEMPLATE FROM OVERVIEW
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @pick }
    end
  end

  # GET /picks/1/edit
  def edit
    @pick = Pick.find(params[:id])
  end

  # POST /picks
  # POST /picks.json
  def create
    @pick = Pick.create_new_pick_with_user_id(pick_params, current_user.id)

    respond_to do |format|
      if @pick.save
        format.html { 
          # redirect_to picks_url, notice: 'Pick was successfully created.' 
          redirect_to :root, notice: 'Pick was successfully created.' 
        }
        format.json { render json: @pick, status: :created, location: @pick }
      else
        format.html { redirect_to :root, notice: "You can't pick the same team twice, and you can't make a pick when you're knocked out" }
        format.json { render json: @pick.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /picks/1
  # PUT /picks/1.json
  def update
    @pick = Pick.find(params[:id])

    respond_to do |format|
      if @pick.update_attributes(params[:pick])
        format.html { redirect_to @pick, notice: 'Pick was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @pick.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /picks/1
  # DELETE /picks/1.json
  def destroy
    @pick = Pick.find(params[:id])
    @pick.destroy

    respond_to do |format|
      format.html { redirect_to picks_url }
      format.json { head :no_content }
    end
  end


  def pick_params
    params.require(:pick).permit(:team_id, :why_pick, :comment, :week_id, :second_team_id)
  end
end
