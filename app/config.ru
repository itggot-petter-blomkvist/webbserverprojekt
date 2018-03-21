require 'bundler'
Bundler.require

#Include model files
Dir["./models/**/*.rb"].each do |f|
    require_relative f
end

DataMapper.database = "./databases/database.sqlite"
Poll.set_allow_anonymous(false)
#Run application
require_relative 'app.rb'
run App