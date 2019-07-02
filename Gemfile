source 'https://rubygems.org'

ruby '~> 2.3'

gemspec

group :test do
  gem 'rspec-rails', '~> 3.6'
  gem 'factory_bot_rails'
  gem 'rake', '10.4.2'
  gem 'faker', '~> 1.5'
end

gem 'mumukit-platform', github: 'mumuki/mumukit-platform', branch: 'feature-remove-domain-helpers'
gem 'mumukit-sync', github: 'mumuki/mumukit-sync', branch: 'feature-remove-domain-specific-code'
gem 'mumukit-bridge', github: 'mumuki/mumukit-bridge', branch: 'feature-remove-importable-info'
gem 'mumukit-login', github: 'mumuki/mumukit-login', branch: 'feature-remove-domain-code'

gem 'codeclimate-test-reporter', :group => :test, :require => nil
