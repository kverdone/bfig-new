class Game < ActiveRecord::Base

	# Public: Gets the game for a given week_number and team_id
	#
	# week_id 		- The week id to search for
	# team_id  		- The team_id to search for
	#
	# Returns the first game found in that week_id with that team_id. Could return nil if
	# 	team_id didn't play that week
	def self.game_for_week_id_and_team_id(week_id, team_id)
		week = Week.find(week_id)
		where(week_number: week.week_number, season_id: week.season_id).where("home_team_id = ? OR away_team_id = ?", team_id, team_id).first
	end

	# Public: Checks if a team_id was the winner of the game that called the method.
	#
	# team_id  - The team_id to be checked
	#
	# Returns true if the team_id won, false if they did not win, and raises an error if
	# 	the game is not over, or the team_id specified did not play in the game.
	def did_team_id_win?(team_id)
		raise 'Game not over yet' if home_team_score == nil && away_team_score == nil
		raise 'Team did not play in this game' if home_team_id != team_id && away_team_id != team_id
		home_team_id == team_id ? home_team_score > away_team_score : away_team_score > home_team_score
	end

	# Public: Checks if a game is over by seeing if the home_team_score and away_team_score are present
	#
	# Returns true if scores are present for both teams, false if not
	def is_game_over?
		home_team_score.present? && away_team_score.present?
	end
end
