class WithOrganizationStatus::InPreparation < WithOrganizationStatus::Base

  def teacher_access_mode(user)
    OrganizationAccessMode::Full.new user, organization
  end

  def student_access_mode(user)
    OrganizationAccessMode::ComingSoon.new user, organization
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::Forbidden.new user, organization
  end

  def outsider_access_mode(user)
    OrganizationAccessMode::Forbidden.new user, organization
  end

  def validate!(user = nil)
    raise Mumuki::Domain::UnpreparedOrganizationError unless user
  end

end
