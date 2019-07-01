ENV['RAILS_ENV'] ||= 'test'
ENV['MUMUKI_ENABLED_LOGIN_PROVIDERS'] = 'developer'

require File.expand_path("../dummy/config/environment.rb", __FILE__)
require 'rspec/rails'
require 'codeclimate-test-reporter'
require 'mumukit/core/rspec'
require 'factory_bot_rails'

require 'mumuki/domain/factories'

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = '1'
  config.include FactoryBot::Syntax::Methods
end

require_relative './evaluation_helper'

RSpec.configure do |config|
  config.before(:each) { I18n.locale = :en }

  config.before(:each) do
    if RSpec.current_example.metadata[:organization_workspace] == :test
      create(:public_organization,
          name: 'test',
          book: create(:book, name: 'test', slug: 'mumuki/mumuki-the-book')).switch!
    end
  end

  config.after(:each) do
    Mumukit::Platform::Organization.leave! if RSpec.current_example.metadata[:organization_workspace]
  end
end

Mumukit::Platform.configure do |config|
  config.application = Mumukit::Platform::Application::Organic.new 'http://sample.app.com', Mumukit::Platform.organization_mapping
end

Mumukit::Auth.configure do |c|
  c.clients.default = {id: 'test-client', secret: 'thisIsATestSecret'}
end

def reindex_organization!(organization)
  organization.reload
  organization.reindex_usages!
end

def reindex_current_organization!
  reindex_organization! Organization.current
end

SimpleCov.start
