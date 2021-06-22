class OrganizationAccessMode::Base
  attr_reader :user, :organization

  def initialize(user, organization = Organization.current)
    @user = user
    @organization = organization
  end

  def validate_active!
  end

  def faqs_here?
    organization.faqs.present?
  end

  def submit_solutions_here?
    false
  end
end

