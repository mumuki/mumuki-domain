class Course < ApplicationRecord
  include Syncable
  include Mumukit::Platform::Course::Helpers

  validates_presence_of :slug, :shifts, :code, :days, :period, :description, :organization_id
  validates_uniqueness_of :slug
  belongs_to :organization

  has_one :invitation

  def import_from_resource_h!(resource_h)
    update! Mumukit::Platform::Course::Helpers.slice_platform_json(resource_h)
  end

  def slug=(slug)
    s = Mumukit::Auth::Slug.parse(slug)

    self[:slug] = slug
    self[:code] = s.course
    self[:organization_id] = Organization.find_by!(name: s.organization).id
  end

  def invite!(expiration_date)
    generate_invitation! expiration_date if closed?
    invitation
  end

  def closed?
    invitation.blank? || invitation.expired?
  end

  def generate_invitation!(expiration_date)
    invitation = build_invitation expiration_date: expiration_date, course: self
    invitation.save_and_notify!
  end


  def self.sync_key_id_field
    :slug
  end
end
