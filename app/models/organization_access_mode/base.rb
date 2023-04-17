class OrganizationAccessMode::Base
  attr_reader :user, :organization

  def initialize(user, organization)
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

  def show_content_element?
    false
  end

  def restore_indicators?(_content)
    false
  end

  def read_only?
    false
  end

  def validate_content_here!(content)
    raise Mumuki::Domain::ForbiddenError unless show_content?(content)
  end
end
