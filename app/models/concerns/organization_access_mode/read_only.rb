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

  private

  def has_scope(key, *keys)
    @scopes.dig(key, *keys).present?
  end
end