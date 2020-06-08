module Mumuki::Domain::Helpers::Organization
  extend ActiveSupport::Concern
  include Mumukit::Platform::Notifiable

  included do
    delegate *Mumuki::Domain::Organization::Theme.accessors, to: :theme
    delegate *Mumuki::Domain::Organization::Settings.accessors, :private?, :login_settings, to: :settings
    delegate *Mumuki::Domain::Organization::Profile.accessors, :locale_json, to: :profile
  end

  def platform_class_name
    :Organization
  end

  def slug
    Mumukit::Auth::Slug.join_s name
  end

  def to_mumukit_grant
    slug.to_mumukit_grant
  end

  def to_mumukit_slug
    slug
  end

  def central?
    name == 'central'
  end

  def test?
    name == 'test'
  end

  def base?
    name == 'base'
  end

  def switch!
    Mumukit::Platform::Organization.switch! self
  end

  def to_s
    name
  end

  def url_for(path)
    Mumukit::Platform.application.organic_url_for(name, path)
  end

  def url
    url_for '/'
  end

  def domain
    Mumukit::Platform.application.organic_domain(name)
  end

  ## API Exposure

  def to_param
    name
  end

  ## Resource Hash

  module ClassMethods
    def current
      Mumukit::Platform::Organization.current
    end

    def parse(json)
      json
        .slice(:name)
        .merge(theme: Mumuki::Domain::Organization::Theme.parse(json[:theme]))
        .merge(settings: Mumuki::Domain::Organization::Settings.parse(json[:settings]))
        .merge(profile: Mumuki::Domain::Organization::Profile.parse(json[:profile]))
    end
  end
end
