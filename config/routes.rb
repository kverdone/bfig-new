Bfig::Application.routes.draw do

  resources :seasons
  devise_scope :user do
    get "signup", to: "devise/registrations#new"
  end
  get 'seasons/:season_id/open' => "seasons#open_signups"
  get 'seasons/:season_id/close' => "seasons#close_signups"
  get 'next-season/sign-up' => 'user_seasons#create'
  get 'weeks/:week_number/pick' => "picks#new"
  get 'weeks/:week_id/open' => "weeks#open"
  get 'weeks/:week_id/close' => "weeks#close"
  get 'weeks/:week_id/review' => "commissioners#review"
  get 'picks/spreadsheet'
  resources :weeks
  get 'picks/make'
  get '/referrals' => 'user_seasons#referrals'

  put "games" => "games#create"
  get "commissioners/index"
  get "commissioners/users"
  get "commissioners/bookmarks"
  post "commissioners/approve"
  post "commissioners/approve_user_season"
  post "commissioners/verify_user"
  post "commissioners/bookmark_comment"
  
  resources :games

  resources :teams
  get 'pool-history' => "picks#history"
  get 'rules' => "picks#rules"
  resources :picks, :except => [:destroy, :show, :edit, :index]


  devise_for :users

  
  root :to => 'picks#overview'
end
