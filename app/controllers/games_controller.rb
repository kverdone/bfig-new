class GamesController < ApplicationController
  before_filter :ensure_admin
  # GET /games
  # GET /games.json
  def index
    @games = Game.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @games }
    end
  end

  # GET /games/1
  # GET /games/1.json
  def show
    @game = Game.find(params[:id])
    logger.debug "in show"
    respond_to do |format|
      format.js
      format.html # show.html.erb
      
    end
  end

  # GET /games/new
  # GET /games/new.json
  def new
    @game = Game.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @game }
    end
  end

  # GET /games/1/edit
  def edit
    @game = Game.find(params[:id])
  end

  # POST /games
  # POST /games.json
  def create
    @game = Game.new(game_params)
    return render :nothing => true if @game.home_team_id.nil? && @game.away_team_id.nil?
    respond_to do |format|
      if @game.save
        # format.html { redirect_to @game, notice: 'Game was successfully created.' }
        format.js
      else
        format.html { render action: "new" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /games/1
  # PUT /games/1.json
  def update
    @game = Game.find(params[:id])

    respond_to do |format|
      if @game.update_attributes(game_params)
        if @game.home_team_id.nil? && @game.away_team_id.nil?
          @game.destroy
        end
        Rails.cache.delete("record_of_teams_picked_in_week_id_#{Week.where(week_number: @game.week_number).last.id}")
        Rails.cache.delete("number_of_losses_in_week_id_#{Week.where(week_number: @game.week_number).last.id}")
        Rails.cache.delete("number_knocked_out_in_week_id_#{Week.where(week_number: @game.week_number).last.id}")
        
        format.js
      else
        format.html { render action: "edit" }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    respond_to do |format|
      format.html { redirect_to games_url }
      format.json { head :no_content }
    end
  end
  def ensure_admin
    if current_user.try(:is_admin) != 1
      redirect_to root_path, error: "you are not an admin"
      return
    end
  end


  private

  def game_params
    params.require(:game).permit(:away_team_id, :away_team_score, :home_team_id, :home_team_score, :week_number, :season_id) 
  end
end
