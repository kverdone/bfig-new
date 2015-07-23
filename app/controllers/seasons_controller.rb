class SeasonsController < ApplicationController
  before_filter :ensure_admin

  def index
    @seasons = Season.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @season = Season.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    @season = Season.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def create

    @season = Season.new(season_params)

    respond_to do |format|
      if @season.save
        format.html { redirect_to '/commissioners/index', notice: 'Season was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  def open_signups
    @season = Season.find(params[:season_id])
    @season.update_attribute(:signup_status, 1)
    redirect_to "/commissioners/index", :notice => "Season #{@season.year} is open for signups"
  end

  def close_signups
    @season = Season.find(params[:season_id])
    @season.update_attribute(:signup_status, 2)
    redirect_to "/commissioners/index", :notice => "Season #{@season.year} is closed for signups"
  end

  def ensure_admin
    if current_user.try(:is_admin) != 1
      redirect_to root_path, error: "you are not an admin"
      return
    end
  end

  private

  def season_params
    params.require(:season).permit(:signup_status, :year)
  end
end
