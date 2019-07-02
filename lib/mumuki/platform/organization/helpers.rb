module Mumukit::Platform::Organization::Helpers
  extend ActiveSupport::Concern
  include Mumukit::Platform::Notifiable

  ## Implementors must declare the following methods:
  #
  #  * name
  #  * book
  #  * profile
  #  * settings
  #  * theme

  included do
    delegate *Mumukit::Platform::Organization::Theme.accessors, to: :theme
    delegate *Mumukit::Platform::Organization::Settings.accessors, :private?, :login_settings, to: :settings
    delegate *Mumukit::Platform::Organization::Profile.accessors, :locale_json, to: :profile
  end

  def platform_class_name
    :Organization
  end

  def slug
    Mumukit::Auth::Slug.join_s name
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

  ## Name validation

  def self.valid_name?(name)
    !!(name =~ anchored_valid_name_regex)
  end

  def self.anchored_valid_name_regex
    /\A#{valid_name_regex}\z/
  end

  def self.valid_name_regex
    /([-a-z0-9_]+(\.[-a-z0-9_]+)*)?/
  end

  ## Resource Hash

  def self.slice_resource_h(resource_h)
    resource_h.slice(:name, :book, :profile, :settings, :theme)
  end

  def to_resource_h
    {
      name: name,
      book: book.slug,
      profile: profile,
      settings: settings,
      theme: theme
    }.except(*protected_resource_fields).compact
  end

  def protected_resource_fields
    []
  end

  module ClassMethods
    def current
      Mumukit::Platform::Organization.current
    end

    def parse(json)
      json
        .slice(:name)
        .merge(theme: Mumukit::Platform::Organization::Theme.parse(json[:theme]))
        .merge(settings: Mumukit::Platform::Organization::Settings.parse(json[:settings]))
        .merge(profile: Mumukit::Platform::Organization::Profile.parse(json[:profile]))
    end
  end
end
