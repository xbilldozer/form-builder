# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] = 'test'
ENV["RACK_ENV"] = 'test'

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'dm-migrations'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :rspec
  
  config.before(:each) do
    DataMapper.auto_migrate!
  end
end
