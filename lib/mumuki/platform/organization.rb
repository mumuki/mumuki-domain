module Mumukit::Platform::Organization
  def self.switch!(organization)
    raise 'Organization must not be nil' unless organization
    Thread.current[:organization] = organization
  end

  def self.leave!
    Thread.current[:organization] = nil
  end

  def self.current
    Thread.current[:organization] || raise('organization not selected')
  end

  def self.current?
    !!Thread.current[:organization]
  end

  def self.current_locale
    Thread.current[:organization]&.locale || 'en'
  end

  def self.find_by_name!(name)
    Mumukit::Platform.organization_class.find_by_name!(name)
  end
end

require_relative './organization/settings'
require_relative './organization/profile'
require_relative './organization/theme'
require_relative './organization/helpers'
