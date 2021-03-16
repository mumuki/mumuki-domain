class Invitation < ApplicationRecord
  include Mumuki::Domain::Syncable,
          WithGeneratedCode

  belongs_to :course

  validate :ensure_not_expired, on: :create

  def ensure_not_expired
    errors.add(:base, :invitation_expired) if expired?
  end

  def import_from_resource_h!(json)
    update! json.merge(course: Course.locate!(json[:course]))
  end

  def organization
    course.organization
  end

  def course_slug
    course.slug
  end

  def navigable_name
    I18n.t(:invitation_for, course: course_name)
  end

  def to_resource_h
    {code: code, course: course_slug, expiration_date: expiration_date}
  end

  def navigation_end?
    true
  end

  def to_param
    code
  end

  def expired?
    expiration_date.past?
  end

  def unexpired
    raise Mumuki::Domain::GoneError, "This invitation has already expired" if expired?
    self
  end

  private

  def self.code_size
    4
  end

  def course_name
    course.name
  end

  def self.sync_key_id_field
    :code
  end
end
