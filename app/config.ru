require 'bundler'
Bundler.require

#Setup database helper
require_relative 'database.rb'
Database.set_database_file "./db/database.sqlite"

#Include model files
Dir["./models/**/*.rb"].each do |f|
    require_relative f
end

#Run application
require_relative 'app.rb'
run App