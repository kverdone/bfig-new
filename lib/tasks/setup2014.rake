desc "Setting up for 2014 season"
task :setup2014 => :environment do
	puts "Destroying past users that never completed a season"
	User.destroy_unparticipating_users!		
	puts "Migrating DB to include referral specific fields"
	Rake::Task['db:migrate'].invoke
	puts "Generating referral codes for all existing users"
	User.all.each{|x| x.generate_referral_code!}
	puts "Marking all existing users as verified"
	User.all.each{|x| x.update_attribute(:verified, true)}
	puts "Enjoy 2014!"
end


