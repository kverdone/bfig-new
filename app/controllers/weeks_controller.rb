class WeeksController < ApplicationController
  before_filter :ensure_admin
  # GET /weeks
  # GET /weeks.json
  def index
    @weeks = Week.all.order(:season_id, :week_number)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @weeks }
    end
  end

  def open
    Rails.cache.delete('alive_primary_pool_users')
    Rails.cache.delete('alive_secondary_pool_users')
    
    
    @week = Week.find(params[:week_id])
    @week.update_attribute(:open,true)
    redirect_to "/commissioners/index", :notice => "Week ##{@week.week_number} is now open for picking"
  end

  def close
    Rails.cache.delete('primary_spreadsheet_data')
    Rails.cache.delete('secondary_spreadsheet_data')
    @week = Week.find(params[:week_id])
    @week.update_attribute(:closed,true)
    redirect_to "/commissioners/index", :notice => "Week ##{@week.week_number} is now closed for picking"
  end

  # GET /weeks/1
  # GET /weeks/1.json
  def show
    @week = Week.find(params[:id])
    @games = []
    Game.where(:season_id => @week.season_id).where(:week_number => @week.week_number).each do |game|
      @games << game
    end
    while @games.count < 17
      @games << Game.new
    end
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @week }
    end
  end

  # GET /weeks/new
  # GET /weeks/new.json
  def new
    @week = Week.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @week }
    end
  end

  # GET /weeks/1/edit
  def edit
    @week = Week.find(params[:id])
  end

  # POST /weeks
  # POST /weeks.json
  def create
    logger.debug params.inspect
    @week = Week.new(week_params)

    respond_to do |format|
      if @week.save
        format.html { redirect_to @week, notice: 'Week was successfully created.' }
        format.json { render json: @week, status: :created, location: @week }
      else
        format.html { render action: "new" }
        format.json { render json: @week.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /weeks/1
  # PUT /weeks/1.json
  def update
    @week = Week.find(params[:id])

    respond_to do |format|
      if @week.update_attributes(params[:week])
        format.html { redirect_to @week, notice: 'Week was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @week.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /weeks/1
  # DELETE /weeks/1.json
  def destroy
    @week = Week.find(params[:id])
    @week.destroy

    respond_to do |format|
      format.html { redirect_to weeks_url }
      format.json { head :no_content }
    end
  end

  def ensure_admin
    if current_user.try(:is_admin) != 1
      redirect_to root_path, error: "you are not an admin"
      return
    end
  end

  def week_params
    params.require(:week).permit(:open, :closed, :week_number, :season_id)
  end
end
