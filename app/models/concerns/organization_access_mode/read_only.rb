class OrganizationAccessMode::ReadOnly < OrganizationAccessMode::Base
  def initialize(user, *global_scopes, **specific_scopes)
    super user
    @scopes = global_scopes.map { |scope| [scope, :all] }.to_h.merge specific_scopes
  end

  def faqs_here?
    has_scope(:faqs) && super
  end

  def profile_here?
    has_scope(:profile)
  end

  private

  def has_scope(key, *keys)
    @scopes.dig(key, *keys).present?
  end
end