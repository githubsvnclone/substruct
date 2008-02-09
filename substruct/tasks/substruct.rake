desc "Loads the base data for things like countries into the current environment's database"
task :load_authority_data => :environment do
  ActiveRecord::Base.establish_connection(RAILS_ENV)
  file = "#{RAILS_ROOT}/vendor/plugins/substruct/db/authority_data.sql"
  IO.readlines(file).join.split("\n\n").each do |table|
    ActiveRecord::Base.connection.execute(table)
  end
  puts "Authority data loaded into the #{RAILS_ENV} database"
end