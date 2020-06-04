class Course < ApplicationRecord
  include Mumuki::Domain::Syncable
  include Mumuki::Domain::Helpers::Course
  include Mumuki::Domain::Area

  validates_presence_of :slug, :shifts, :code, :days, :period, :description, :organization_id
  validates_uniqueness_of :slug
  belongs_to :organization

  has_many :invitations

  alias_attribute :name, :code

  resource_fields :slug, :shifts, :code, :days, :period, :description

  def current_invitation
    invitations.where('expiration_date > ?', Time.now).first
  end

  def import_from_resource_h!(resource_h)
    update! self.class.slice_resource_h(resource_h)
  end

  def slug=(slug)
    s = slug.to_mumukit_slug
    self[:slug] = slug.to_s
    self[:organization_id] = Organization.locate!(s.organization).id
  end

  def invite!(expiration_date)
    if closed?
      create_invitation_for expiration_date
    else
      current_invitation
    end
  end

  def closed?
    current_invitation.blank? || current_invitation.expired?
  end

  def create_invitation_for(expiration_date)
    invitations.create expiration_date: expiration_date, course: self
    current_invitation
  end

  def self.sync_key_id_field
    :slug
  end

  def to_organization
    organization
  end

  def to_s
    slug.to_s
  end

  def self.allowed(organization, permissions)
    where(organization: organization).select { |course| permissions.has_permission? :teacher, course.slug }
  end
end
