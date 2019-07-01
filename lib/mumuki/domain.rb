require "mumuki/domain/engine"

require 'mumukit/core'
require 'mumukit/core/activemodel'
require 'mumukit/assistant'
require 'mumukit/auth'
require 'mumukit/bridge'
require 'mumukit/content_type'
require 'mumukit/directives'
require 'mumukit/inspection'
require 'mumukit/platform'
require 'mumukit/randomizer'
require 'mumukit/sync'
require 'mumukit/login'

I18n.load_translations_path File.join(__dir__, 'domain', 'locales', '**', '*.yml')

module Mumuki
  module Domain
  end
end

Mumukit::Platform.configure do |config|
  config.user_class_name = 'User'
  config.organization_class_name = 'Organization'
end

require_relative './domain/evaluation'
require_relative './domain/submission'
require_relative './domain/status'
require_relative './domain/exceptions'
require_relative './domain/file'
require_relative './domain/extensions'
require_relative './domain/organization'
require_relative './domain/helpers'
require_relative './domain/syncable'
require_relative './domain/stores'

class Mumukit::Assistant
  def self.valid?(rules)
    !!parse(rules.map(&:deep_symbolize_keys)) rescue false
  end
end

class Mumukit::Expectation
  def self.valid?(expectation)
    !!Mumukit::Inspection.parse(expectation['inspection']) rescue false
  end
end

class Mumukit::Randomizer
  def self.valid?(randomizations)
    !!parse(randomizations) rescue false
  end
end

