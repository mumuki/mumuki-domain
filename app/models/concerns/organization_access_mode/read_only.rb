class OrganizationAccessMode::ReadOnly < OrganizationAccessMode::Base
  def initialize(user, organization, *global_scopes, **specific_scopes)
    super user, organization
    @scopes = global_scopes.map { |scope| [scope, :all] }.to_h.merge specific_scopes
  end

  def faqs_here?
    has_scope(:faqs) && super
  end

  def profile_here?
    has_scope(:profile)
  end

  def discuss_here?
    has_scope(:discussions) && super
  end

  def validate_discuss_here?(discussion)
    super(discussion) unless discussion&.initiator == user
  end

  def show_content?(content)
    has_scope(:exercises) ||
      (has_scope(:exercises, :submitted) && content.has_progress_for?(user, organization))
  end

  def validate_content_here?(content)
    raise Mumuki::Domain::GoneError unless show_content?(content)
  end

  private

  def has_scope(key, value = :all)
    @scopes[key] == value
  end
end