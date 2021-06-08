class WithOrganizationStatus::InPreparation < WithOrganizationStatus::Base

  def student_access_mode(user)
    OrganizationAccessMode::ComingSoon.new user
  end

  def ex_student_access_mode(user)
    OrganizationAccessMode::Forbidden.new user
  end

  def outsider_access_mode(user)
    OrganizationAccessMode::Forbidden.new user
  end

  def validate!(user)
    raise Mumuki::Domain::UnpreparedOrganizationError unless user
  end

end
