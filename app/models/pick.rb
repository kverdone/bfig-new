class Pick < ActiveRecord::Base
	# attr_accessible :team_id, :why_pick, :comment, :week_id, :second_team_id
	belongs_to :user
	belongs_to :team
	belongs_to :week
	# validate :user_can_make_a_pick
	validate :user_has_not_picked_team_before

	# Public: Takes a pick hash, a user_id, and creates a pick,
	# 	destroying any existing ones for the same week
	#
	# Returns the newly created pick, marking it as a second_chance pick if 
	# 	the user's status is 2
	def self.create_new_pick_with_user_id(a_pick, a_user_id)
		existing_pick = Pick.where(:week_id => a_pick[:week_id], :user_id => a_user_id).first
    	existing_pick.destroy if existing_pick.present?
    	the_users_status = User.find(a_user_id).status
    	@pick = Pick.new(a_pick)
   	 	@pick.user_id = a_user_id
   	 	@pick.is_second_chance = true if the_users_status == 2
		@pick
	end

	def self.weekly_stats
		picks_for_this_week = Pick.where(is_second_chance: nil, week_id: Week.last_closed_week_id)
		picks_grouped_by_team = picks_for_this_week.group_by{|x| x.team_id}
		team_id_and_number_of_picks = {}
		picks_grouped_by_team.each do |key, value|
			team_id_and_number_of_picks[key] = value.length
		end
		return team_id_and_number_of_picks.sort_by{|key, value| -1 * value}.take(5)
	end

	# Public: Forms a string of the pick's team mascot(s), for display
	# 	on the frontend
	#
	# Returns the team_mascot if one team picked, and a formatted string with 
	# 	both team mascots if two teams picked
	def pick_mascot_string
		second_team_id.present? ? "#{Team.find(team_id).mascot}, #{Team.find(second_team_id).mascot}" : team.mascot
	end

	def second_team
		Team.find(second_team_id)
	end

	# Public: Checks if a pick is a winner. If the pick is a second_chance pick
	# 	with two teams, it pulls that game and checks it too
	#
	# Returns true if all of the teams in the pick won their games, and false if not
	def is_a_winner?
		if second_team_id.present?
			second_game = Game.game_for_week_id_and_team_id(week_id, second_team_id)
			return pick_game.did_team_id_win?(team_id) && second_game.did_team_id_win?(second_team_id)
		end
		return pick_game.did_team_id_win?(team_id)
	end

	# Public: Checks if all games involved in the pick are over. If the pick is
	# 	a second_chance pick with two teams, it pulls that game and checks it too
	#
	# Returns true if all of the games in the pick are over, and false if not
	def is_game_over?
		if second_team_id.present?
			second_game = Game.game_for_week_id_and_team_id(week_id, second_team_id)
			return pick_game.is_game_over? && second_game.is_game_over?
		end
		return pick_game.is_game_over?
	end

	# Public: Gets the week_number of the game picked
	#
	# Returns an integer, the week_number
	def week_number
		Week.find(week_id).week_number
	end

	# Public: Gets the game that team_id is playing in
	#
	# Returns a single game, that the pick is concerned with
	def pick_game
		Game.select("home_team_id, home_team_score, away_team_id, away_team_score").
			game_for_week_id_and_team_id(week_id, team_id)
	end

	# Public: Gets all of the teams picked in the primary pool for 
	# 	a given week_id
	#
	# week_id - The week_id we're concerned with
	# 
	# Returns a unique array of teams picked in the given week_id
	def self.teams_picked_in_week_id(week_id)
		Team.where(:id => Pick.where(week_id: week_id).where(:is_second_chance => nil).pluck(:team_id))
	end

	def self.cache_record_of_teams_picked_in_week_id(week_id)
		Rails.cache.fetch("record_of_teams_picked_in_week_id_#{week_id}") { 
			self.record_of_teams_picked_in_week_id(week_id)
		}
	end

	def self.record_of_teams_picked_in_week_id(week_id)
		team_ids = Pick.teams_picked_in_week_id(week_id).pluck(:id)
		wins, losses = 0, 0
		team_ids.each do |team_id|
			if Game.game_for_week_id_and_team_id(week_id, team_id).did_team_id_win?(team_id)
				wins = wins+1
			else
				losses = losses + 1
			end
		end
		return "#{wins}-#{losses}"
	end

	def self.primary_users_who_have_not_picked
		this_week = Week.current_pick_week
		@grouped_users = User.grouped_by_status
		@primary_picks = Pick.where(:week_id => this_week.id).where(:is_second_chance => nil).includes([:user]).sort_by{|x| [x.team.short_city_name, x.user.full_name]}
    
    	@users_who_havent_picked_emails = @grouped_users[1].collect{|y| y.email} - @primary_picks.collect{|x| x.user.email }

    	return @users_who_havent_picked_emails.join(", ")
	end

	def self.secondary_users_who_have_not_picked
		this_week = Week.current_pick_week
		@grouped_users = User.grouped_by_status
		@secondary_picks = Pick.where(:week_id => this_week.id).where(:is_second_chance => true).includes([:user]).sort_by{|x| [x.team.short_city_name, x.user.full_name]}
    
    	@second_users_who_havent_picked_emails = @grouped_users[2].collect{|y| y.email} - @secondary_picks.collect{|x| x.user.email }  

    	return @second_users_who_havent_picked_emails.join(", ")
	end

	def self.cache_number_of_losses_in_week_id(week_id)
		Rails.cache.fetch("number_of_losses_in_week_id_#{week_id}") { 
			Week.find(week_id).losing_primary_picks.count + Week.find(week_id).users_who_missed_their_pick.count
		}
	end

	def self.cache_number_remaining_after_week_id(week_id)
		Rails.cache.fetch("number_of_users_remaining_after_week_id_#{week_id}") { 
			Week.find(week_id).user_ids_who_can_pick_in_primary_pool.count - Pick.cache_number_of_losses_in_week_id(week_id)
		}
	end

	def self.number_of_losses_in_week_id(week_id)
		where(week_id: week_id).where(:is_second_chance => nil).select{|x| !x.is_a_winner? }.count
	end

	private 

	def user_can_make_a_pick
		if User.find(self.user_id).status != 1
			errors.add(:base, 'user is knocked out')
		end
	end

	def user_has_not_picked_team_before
		if is_second_chance == nil && User.find(self.user_id).primary_pool_picks.pluck(:team_id).include?(self.team_id)
			errors.add(:base, 'already picked that team')
		end
		if is_second_chance == true && User.find(self.user_id).secondary_pool_picks.pluck(:team_id).include?(self.team_id)
			errors.add(:base, 'already picked that team')
		end
	end

	# Voodoo magic to get the primary spreadsheet data
	def self.calculate_primary_spreadsheet_data
		User.where("id IN (?)", UserSeason.where(approved: true).user_ids_in_current_season).map{|x| {:user_id => x.id,
                        :user_status => x.status,
                        :user_name => x.full_name, 
                        :array_of_picks_with_team_info => x.array_of_picks_with_team_info} }.sort_by{|y| [-y[:array_of_picks_with_team_info].count, y[:array_of_picks_with_team_info].collect{|x| x.short_city_name}.reverse, y[:user_name]]}
	end

	# Voodoo magic to get the secondary spreadsheet data
	def self.calculate_secondary_spreadsheet_data
		User.where(id: Pick.where(:is_second_chance => true, :week_id => Week.closed_second_chance_pick_week_ids).pluck(:user_id)).map{|x| {:user_id => x.id,
                        :user_status => x.status,
                        :user_name => x.full_name, 
                        :secondary_array_of_picks_with_team_info => x.secondary_array_of_picks_with_team_info,
                        :array_of_double_picks_with_team_info => x.array_of_double_picks_with_team_info
                        } }.sort_by{|y| [-y[:secondary_array_of_picks_with_team_info].count, y[:secondary_array_of_picks_with_team_info].collect{|x| x.short_city_name}.reverse, y[:user_name]]}
	end
end
