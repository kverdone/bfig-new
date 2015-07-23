class Team < ActiveRecord::Base

	def record
		wins, losses = 0, 0
		Game.where("home_team_id = ? AND home_team_score IS NOT NULL", id).where(season_id: Season.current_season).each do |a_game|
			if a_game.home_team_score > a_game.away_team_score
				wins += 1
			else
				losses += 1
			end
		end
		Game.where("away_team_id = ? AND away_team_score IS NOT NULL", id).where(season_id: Season.current_season).each do |a_game|
			if a_game.away_team_score > a_game.home_team_score
				wins += 1
			else
				losses += 1
			end
		end
		return "#{wins} - #{losses}"
	end
end
