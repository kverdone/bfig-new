class Week < ActiveRecord::Base
	# attr_accessible :open, :closed, :week_number, :season_id
	belongs_to :season
	has_many :picks

	def teams_picked
		Team.where(:id => primary_picks.pluck(:team_id))
	end

	def record_of_teams_picked
		team_ids = teams_picked.pluck(:id)
		wins, losses = 0, 0
		team_ids.each do |team_id|
			if Game.game_for_week_id_and_team_id(id, team_id).did_team_id_win?(team_id)
				wins = wins+1
			else
				losses = losses + 1
			end
		end
		return "#{wins}-#{losses}"
	end

	def cache_record_of_teams_picked
		Rails.cache.fetch("record_of_teams_picked_in_week_id_#{id}") { 
			record_of_teams_picked
		}
	end

	def number_knocked_out
		losing_primary_picks.count + users_who_missed_their_pick.count
	end

	def cache_number_knocked_out
		Rails.cache.fetch("number_knocked_out_in_week_id_#{id}") { 
			number_knocked_out
		}
	end

	def number_remaining
		user_ids_who_can_pick_in_primary_pool.count - number_knocked_out
	end

	def cache_number_remaining
		Rails.cache.fetch("number_remaining_after_week_id_#{id}") { 
			number_remaining
		}
	end

	def user_ids_who_can_pick_in_primary_pool
		if week_number > 1
			return previously_completed_week.winning_primary_picks.collect{|x| x.user_id}
		else
			return Season.current_season.approved_user_ids
		end
	end

	def users_who_missed_their_pick
		user_ids_who_can_pick_in_primary_pool - primary_picks.pluck(:user_id)
	end

	def calc_spread
		if week_number > 1
			Rails.cache.fetch("spreadsheet_for_week_id_#{id}") {
				spreadsheet = previously_completed_week.calc_spread
				# for each user that's still alive, see if the previous pick was a winner. if not, mark them as out
				spreadsheet.each_with_index do |x,index|
					# if they missed pick, theyre out
					if x[:picks_array].count < week_number-1 # i.e. current week is #2. If they have less than (2-1=0) picks, they're out
						x[:alive] = false
					else 
						# else if pick was a loser, theyre out
						last_week_pick = Pick.find(x[:picks_array][week_number-2][:id])
						if !last_week_pick.is_a_winner?
							x[:alive] = false
						else
							# if pick was a winner, add their current week pick to the end of their array
							this_week_pick = primary_picks.where(user_id: x[:user_id]).first
							if this_week_pick.present?
								pick_hash = {team: this_week_pick.team.short_city_name, id: this_week_pick.id}
								x[:picks_array] << pick_hash
							else
								# if they didn't make a pick this week, they missed it
								x[:missed_pick] = true
							end
						end
					end
				end
				# spreadsheet.each{|x| x[:picks_array] << {team: 'N/P', id: nil} if x[:missed_pick]}
				# re-sort everybody
				spreadsheet.sort_by{|y| [y[:alive] ? -1 : 0,-y[:picks_array].count, y[:picks_array].collect{|x| x[:team]}.reverse, y[:user_name]]}
			}
		else
			Rails.cache.fetch("spreadsheet_for_week_id_#{id}") {
				User.where("id IN (?)", user_ids_who_can_pick_in_primary_pool).map { |x| 
					{
						:user_id => x.id,
						:alive => true,
						:user_name => x.full_name,
						:picks_array => x.primary_picks_up_to_week_id(id).collect{|x| {team: x.team.short_city_name, id: x.id}},
						:missed_pick => x.primary_picks_up_to_week_id(id).empty?
					}
				 }.sort_by{|y| [-y[:picks_array].count, y[:picks_array].collect{|x| x[:team]}.reverse, y[:user_name]]}
			 }
		end
	end

	def calc_secondary_spread
		if week_number > Week.second_chance_week_number_start
			Rails.cache.fetch("secondary_spreadsheet_for_week_id_#{id}") {
				spreadsheet = previously_completed_week.calc_secondary_spread
				# for each user that's still alive, see if the previous pick was a winner. if not, mark them as out
				spreadsheet.each_with_index do |x,index|
					# if they missed pick, theyre out
					if x[:picks_array].count < week_number-Week.second_chance_week_number_start
						x[:alive] = false
					else 
						# else if pick was a loser, theyre out
						last_week_pick = Pick.find(x[:picks_array][week_number-Week.second_chance_week_number_start-2][:id])
						if !last_week_pick.is_a_winner?
							x[:alive] = false
						else
							# if pick was a winner, add their current week pick to the end of their array
							this_week_pick = secondary_picks.where(user_id: x[:user_id]).first
							if this_week_pick.present?
								pick_hash = {team: this_week_pick.team.short_city_name, id: this_week_pick.id}
								x[:picks_array] << pick_hash
								if this_week_pick.second_team_id
									x[:double_picks_array] << {team: this_week_pick.second_team.short_city_name}
								end
							else
								# if they didn't make a pick this week, they missed it
								x[:missed_pick] = true
							end
						end
					end
				end
				# spreadsheet.each{|x| x[:picks_array] << {team: 'N/P', id: nil} if x[:missed_pick]}
				# re-sort everybody
				spreadsheet.sort_by{|y| [y[:alive] ? -1 : 0,-y[:picks_array].count, y[:picks_array].collect{|x| x[:team]}.reverse, y[:user_name]]}
			}
		else
			Rails.cache.fetch("secondary_spreadsheet_for_week_id_#{id}") {
				User.where("id IN (?)", user_ids_who_can_pick_in_secondary_pool).map { |x| 
					{
						:user_id => x.id,
						:alive => true,
						:user_name => x.full_name,
						:picks_array => secondary_picks.select{|y| y.user_id == x.id}.collect{|z| {team: z.team.short_city_name, id: z.id}},
						:double_picks_array => [],
						:missed_pick => secondary_picks.select{|y| y.user_id == x.id}.empty?
					}
				 }.sort_by{|y| [-y[:picks_array].count, y[:picks_array].collect{|x| x[:team]}.reverse, y[:user_name]]}
			 }
		end
	end

=begin
User.where(id: Pick.where(:is_second_chance => true, :week_id => Week.closed_second_chance_pick_week_ids).pluck(:user_id)).map{|x| {:user_id => x.id,
                        :user_status => x.status,
                        :user_name => x.full_name, 
                        :secondary_array_of_picks_with_team_info => x.secondary_array_of_picks_with_team_info,
                        :array_of_double_picks_with_team_info => x.array_of_double_picks_with_team_info
                        } }.sort_by{|y| [-y[:secondary_array_of_picks_with_team_info].count, y[:secondary_array_of_picks_with_team_info].collect{|x| x.short_city_name}.reverse, y[:user_name]]}

=end

	def primary_picks
		picks.where(is_second_chance: nil)
	end

	def winning_primary_picks
		primary_picks.select{|x| x.is_a_winner? }
	end

	def losing_primary_picks
		primary_picks.select{|x| !x.is_a_winner? }
	end

	def user_ids_who_can_pick_in_secondary_pool
		# if we're well into second chance
		if week_number > Week.second_chance_week_number_start
			return previously_completed_week.winning_secondary_picks.collect{|x| x.user_id}
		# if we're in the first week of second chance
		elsif week_number == Week.second_chance_week_number_start
			# everyone approved EXCEPT those who can pick in this current week
			return Season.current_season.approved_user_ids - self.user_ids_who_can_pick_in_primary_pool
		# if we haven't started second chance, return nil
		else
			raise "don't call this before second chance starts"
		end
	end

	def secondary_picks
		picks.where(is_second_chance: true)
	end

	def winning_secondary_picks
		secondary_picks.select{|x| x.is_a_winner? }
	end

	def games
		Game.where(week_number: week_number, season_id: season_id)
	end

	def all_games_finished?
		games.all?{|x| x.is_game_over? }
	end
	# Public: Gets the current picking week
	#
	# Returns the first week that has open == true and closed == false
	def self.current_pick_week
		Week.where(:open => true, :closed => false, :season_id => Season.current_season).order(:week_number).first
	end

	# Public: Gets the list of closed week ids
	#
	# Returns an array of closed_week_ids
	def self.closed_week_ids
		Week.where(:closed => true, :season_id => Season.current_season).order(:id).pluck(:id)
	end

	def previously_completed_week
		previously_completed_week_id = Week.closed_week_ids.select{|x| x < id }.last
		Week.find(previously_completed_week_id)
	end

	def self.last_closed_week
		self.find(self.closed_week_ids.last)
	end

	def self.last_closed_week_id
		self.last_closed_week.id
	end

	def self.closed_second_chance_pick_week_ids
		Week.where(:closed => true, :season_id => Season.current_season).where("week_number >= ?", Week.second_chance_week_number_start).pluck(:id)
	end	

	# Constant method. Returns the week number that signifies the start of second
	# 	chance pool
	def self.second_chance_week_number_start
		5
	end

	# Constant method. Returns the week number that signifies the start of 
	# 	double picking in second_chance pool
	def self.double_picking_week_number_start
		10
	end

	def has_second_chance_started?
		week_number >= Week.second_chance_week_number_start
	end

	# Public: Checks to see if second_chance picking has started
	#
	# If there is a current week open for picking, it checks to see if that is 
	# 	after second_chance_week_number_start. If no week open for picking, it 
	# 	checks the same thing for the last closed week
	def self.has_second_chance_started?
		Week.current_pick_week ? Week.current_pick_week.week_number >= Week.second_chance_week_number_start : Week.where(:closed => true).order(:id).last.week_number >= Week.second_chance_week_number_start
	end

	# Public: Checks to see if double picking has started in second_chance
	#
	# If there is a current week open for picking, it checks to see if that is 
	# 	after double_picking_week_number_start. If no week open for picking, it 
	# 	checks the same thing for the last closed week
	def self.has_double_picking_started?
		Week.current_pick_week ? Week.current_pick_week.week_number >= Week.double_picking_week_number_start : Week.where(:closed => true).order(:id).last.week_number >= Week.double_picking_week_number_start
	end
end
