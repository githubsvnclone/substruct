# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode
# (Use only when you can't set environment variables through your web/app server)
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below
require 'rubygems'
require_gem 'RedCloth'
require_gem 'payment'
require_gem 'fastercsv'
# Start up substruct
Engines.start :substruct

ActionMailer::Base.server_settings = {
  :address => "",
  :port => 25,
  :domain => "",
  :authentication => :login,
  :user_name => "",
  :password => "",
}

# Globals
ERROR_EMPTY  = 'Please fill in this field.'
ERROR_NUMBER = 'Please enter only numbers (0-9) in this field.'

# Shipping Info - Get this from your boys at FedEx
SHIP_FEDEX_URL = ''
SHIP_FEDEX_ACCOUNT = ''
SHIP_FEDEX_METER = ''
SHIP_SENDER_ZIP = ''
SHIP_SENDER_COUNTRY = ''

# Authorize.net Info
PAY_LOGIN = ''
PAY_PASS = ''
# If this is defined then payment will use it
# If not it defaults to authorize.net
# This is so you can use auth.net's testing facilities
# or perhaps a service like 2CheckOut.com
PAY_URL = nil
# You don't always need this, but it's used if not nil
PAY_TRANS_KEY = nil