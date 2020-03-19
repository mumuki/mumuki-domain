class Course < ApplicationRecord
  include Mumuki::Domain::Syncable
  include Mumuki::Domain::Helpers::Course
  include WithAccessRules

  validates_presence_of :slug, :shifts, :code, :days, :period, :description, :organization_id
  validates_uniqueness_of :slug
  belongs_to :organization

  delegate :book, to: :organization

  has_many :invitations

  alias_attribute :name, :code

  resource_fields :slug, :shifts, :code, :days, :period, :description

  def current_invitation
    invitations.where('expiration_date > ?', Time.now).take
  end

  def import_from_resource_h!(resource_h)
    update! self.class.slice_resource_h(resource_h)
  end

  def slug=(slug)
    s = Mumukit::Auth::Slug.parse(slug)

    self[:slug] = slug
    self[:code] = s.course
    self[:organization_id] = Organization.locate!(s.organization).id
  end

  def invite!(expiration_date)
    if closed?
      generate_invitation! expiration_date
    else
      current_invitation
    end
  end

  def closed?
    current_invitation.blank? || current_invitation.expired?
  end

  def generate_invitation!(expiration_date)
    invitation = invitations.build expiration_date: expiration_date, course: self
    invitation.save_and_notify!
  end

  def self.sync_key_id_field
    :slug
  end
end
