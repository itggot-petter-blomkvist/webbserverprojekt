require 'bundler'
Bundler.require
require_relative 'app.rb'
Dir["./models/**/*.rb"].each do |f|
    require_relative f
end
run App