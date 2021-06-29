class Course < ApplicationRecord
  include Mumuki::Domain::Syncable
  include Mumuki::Domain::Helpers::Course
  include Mumuki::Domain::Area

  validates_presence_of :slug, :period, :code, :description, :organization_id
  validates_uniqueness_of :slug
  belongs_to :organization

  has_many :invitations

  alias_attribute :name, :code

  resource_fields :slug, :shifts, :code, :days, :period, :description, :period_start, :period_end

  def current_invitation
    invitations.where('expiration_date > ?', Time.current).first
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
      generate_invitation! expiration_date
    else
      current_invitation
    end
  end

  def ended?
    period_end.present? && period_end.past?
  end

  def started?
    period_start.present? && period_start.past?
  end

  def infer_period_range!
    return if period_start || period_end

    period =~ /^(\d{4})?/
    year = $1.to_i

    return nil unless year.between? 2014, (DateTime.current.year + 1)

    self.period_start = DateTime.new(year).beginning_of_year
    self.period_end = DateTime.new(year).end_of_year
  end

  def canonical_code
    "#{period}-#{code}".downcase
  end

  def closed?
    current_invitation.blank? || current_invitation.expired?
  end

  def generate_invitation!(expiration_date)
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

  def self.allowed_for(user, organization = Organization.current)
    where(organization: organization).select { |course| user.teacher_of? course.slug }
  end
end
