class Organization::Status::Base

  attr_reader :organization

  def initialize(organization)
    @organization = organization
  end

  def access_mode(user)
    if user&.teacher_of? organization
      teacher_access_mode(user)
    elsif user&.student_of? organization
      student_access_mode(user)
    elsif user&.ex_student_of? organization
      ex_student_access_mode(user)
    else
      outsider_access_mode(user)
    end
  end

  def validate!(user = nil)
    validate_enabled! unless user
  end
end
