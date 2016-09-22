# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"
require File.expand_path("../dummy/config/environment", __FILE__)

# Re-create the test database and run the migrations
db = ENV.fetch("DB", "sqlite3")
system({ "DB" => db }, "script/create-db-users") unless ENV["TRAVIS"]
ActiveRecord::Tasks::DatabaseTasks.drop_current
ActiveRecord::Tasks::DatabaseTasks.create_current
begin
  verbose_was = ActiveRecord::Migration.verbose
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Migrator.migrate(["db/migrate/", File.join(Rails.root, "db/migrate/")])
ensure
  ActiveRecord::Migration.verbose = verbose_was
end

require "rspec/rails"
require "capybara/rspec"
require "pundit/rspec"
require "factory_girl_rails"
require "database_cleaner"
require "fileutils"
require "active_support/testing/time_helpers"

if Rails::VERSION::MAJOR >= 5
  require "rails-controller-testing"
  RSpec.configure do |config|
    [:controller, :view, :request].each do |type|
      config.include ::Rails::Controller::Testing::TestProcess, type: type
      config.include ::Rails::Controller::Testing::TemplateAssertions, type: type
      config.include ::Rails::Controller::Testing::Integration, type: type
    end
  end
end

Dir[Rails.root.join("../../spec/support/**/*.rb")].each { |f| require f }

counter = -1

FileUtils.mkdir("log") unless File.directory?("log")
ActiveRecord::SchemaMigration.logger = ActiveRecord::Base.logger = Logger.new(File.open("log/test.#{db}.log", "w"))

require "capybara-webkit"

sqlite_source = ENV.fetch("SQLITE", ENV["TRAVIS"] ? "file" : "memory")
puts "DB: #{db}"
puts "    #{sqlite_source}" if db == "sqlite3"
if db == "sqlite3" && sqlite_source == "memory"
  require "transactional_capybara/rspec" # so we can do in-memory sqlite
else
  require "transactional_capybara/ajax_helpers" # so we can wait for ajax (only!)
end

Capybara.javascript_driver = ENV["CAPYBARA_JS_DRIVER"].blank? ? :webkit : ENV["CAPYBARA_JS_DRIVER"].to_sym
Capybara::Webkit.configure(&:block_unknown_urls)

dbcleaner_strategy = ENV.fetch("DBCLEANER", ENV["TRAVIS"] && "truncation").try(:to_sym)

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    puts "dbcleaner_strategy: #{dbcleaner_strategy}"
    DatabaseCleaner.strategy = dbcleaner_strategy || :transaction
    DatabaseCleaner.clean_with(:truncation)
    if Rails::VERSION::MAJOR < 5
      # after_commit testing is baked into rails 5.
      require "test_after_commit"
      TestAfterCommit.enabled = true
    end
    ActiveJob::Base.queue_adapter = :inline
  end

  config.after(:suite) do
    counter = 0
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = example.metadata[:js] ? :truncation : :transaction unless dbcleaner_strategy
    DatabaseCleaner.start
    Time.zone = "UTC"
  end

  config.after :each do |example|
    TransactionalCapybara::AjaxHelpers.wait_for_ajax(page) if example.metadata[:js]
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
    counter += 1
    if counter > 9
      GC.enable
      GC.start
      GC.disable
      counter = 0
    end
  end
end
