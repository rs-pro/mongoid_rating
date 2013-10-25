require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")

require "rubygems"
require "rspec"
require "mongoid"
require "database_cleaner"
require "mongoid_rating"

Dir["#{MODELS}/*.rb"].each { |f| require f }

Mongoid.configure do |config|
  config.connect_to "mongoid_rating_test"
end
Mongoid.logger = Logger.new($stdout)

DatabaseCleaner.orm = "mongoid"

RSpec.configure do |config|
  config.before(:all) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
