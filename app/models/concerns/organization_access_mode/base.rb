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

  def discuss_here?
    organization.forum_enabled? && user.discusser_of?(organization) &&
      user.trusted_as_discusser_in?(organization) && !user.banned_from_forum?
  end

  def show_discussion_element?
    false
  end

  def validate_discuss_here?(_discussion)
    raise Mumuki::Domain::ForbiddenError
  end

  def validate_content_here?(content)
    raise Mumuki::Domain::ForbiddenError unless show_content?(content)
  end
end

