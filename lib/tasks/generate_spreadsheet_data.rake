desc "Generating spreadsheet data for current week"
task :generate_primary_spreadsheet => :environment do
	# delete old, out of date spreadsheet
	Rails.cache.delete('primary_spreadsheet_data')

	start_time = Time.now.to_f
	primary_spreadsheet_data = Pick.calculate_primary_spreadsheet_data
    end_time = Time.now.to_f

    Rails.cache.write('primary_spreadsheet_data', primary_spreadsheet_data)
    puts "finished in #{end_time - start_time}"
end

task :generate_secondary_spreadsheet => :environment do
	# delete old, out of date spreadsheet
	Rails.cache.delete('secondary_spreadsheet_data')

	start_time = Time.now.to_f
	secondary_spreadsheet_data = Pick.calculate_secondary_spreadsheet_data
    end_time = Time.now.to_f

    Rails.cache.write('secondary_spreadsheet_data', secondary_spreadsheet_data)
    puts "finished in #{end_time - start_time}"
end
