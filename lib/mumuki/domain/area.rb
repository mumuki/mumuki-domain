module Mumuki::Domain::Area
  extend ActiveSupport::Concern

  def to_mumukit_grant
    slug.to_mumukit_grant
  end

  def to_mumukit_slug
    slug
  end

  required :to_organization
end
