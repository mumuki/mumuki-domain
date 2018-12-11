class Invitation < ApplicationRecord
  include Syncable

  belongs_to :course
  validates_uniqueness_of :code

  defaults do
    self.code = self.class.generate_code
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

  def to_resource_h(*)
    { code: code, course: course_slug, expiration_date: expiration_date }
  end

  def navigation_end?
    true
  end

  def to_param
    code
  end

  def expired?
    Time.now > expiration_date
  end

  def unexpired
    raise RecordNotFound, "This invitation has already expired" if expired?
    self
  end

  def self.generate_code
    SecureRandom.urlsafe_base64 4
  end

  def notify!
    Mumukit::Nuntius.notify_event! 'InvitationChanged', invitation: to_resource_h
  end

  private

  def course_name
    course.name
  end

  def self.sync_key_id_field
    :code
  end
end
