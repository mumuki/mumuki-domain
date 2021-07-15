module Mumuki::Domain::Helpers::User
  extend ActiveSupport::Concern
  include Mumukit::Auth::Roles
  include Mumukit::Platform::Notifiable

  ## Permissions

  delegate :has_role?,
           :add_permission!,
           :remove_permission!,
           :update_permission!,
           :has_permission?,
           :has_permission_delegation?,
           :protect!,
           :protect_delegation!,
           :protect_permissions_assignment!,
           :student_granted_organizations,
           :any_granted_organizations,
           :any_granted_roles,
           to: :permissions

  def platform_class_name
    :User
  end

  def merge_permissions!(new_permissions)
    self.permissions = permissions.merge(new_permissions)
  end

  (Mumukit::Auth::Roles::ROLES - [:writer, :editor, :owner] + [:discusser]).each do |role|
    role_of = "#{role}_of?"
    role_here = "#{role}_here?"

    # Tells whether this user has #{role} permissions in
    # the given `slug_like`
    define_method role_of do |slug_like|
      has_permission? role, slug_like.to_mumukit_slug
    end

    # Tells whether this user has #{role} permissions in
    # the current organization
    define_method role_here do
      send role_of, Mumukit::Platform::Organization.current
    end
  end

  # Tells whether this user has forum discusser permissions in
  # the given organization
  def discusser_of?(organization)
    has_permission? organization.forum_discussions_minimal_role, organization.slug
  end

  (Mumukit::Auth::Roles::ROLES - [:owner]).each do |role|

    # Assignes the #{role} role to this user
    # for the given `grant_like`
    define_method "make_#{role}_of!" do |grant_like|
      add_permission! role, grant_like.to_mumukit_grant
    end
  end

  ## Profile

  def profile_completed?
    self.class.profile_fields.map { |it| self[it] }.all? &:present?
  end

  def to_s
    "#{full_name} <#{email}> [#{uid}]"
  end

  ## Accessible organizations

  revamp_accessor :any_granted_organizations, :student_granted_organizations do |_, _, result|
    result.map { |org| Mumukit::Platform::Organization.find_by_name!(org) rescue nil }.compact
  end

  def has_student_granted_organizations?
    student_granted_organizations.present?
  end

  def main_organization
    student_granted_organizations.first || any_granted_organizations.first
  end

  # Deprecated: use `immersive_organization_at` which
  # properly looks for a single immersive organization taking
  # current organization and path into account
  def has_immersive_main_organization?
    main_organization.try(&:immersive?).present?
  end

  def immersive_organization_at(path_item, current = Organization.current)
    immersive_organizations_at(path_item, current).single
  end

  def immersive_organizations_at(path_item, current = Organization.current)
    usage_filter = path_item ? lambda { |it| path_item.used_in?(it) } : lambda { |_| true }
    immersive_organizations_for(current).select(&usage_filter)
  end

  def immersive_organization_with_content_at(path_item, current = Organization.current)
    orga = immersive_organizations_with_content_at(path_item, current).single
    [orga, path_item&.navigable_content_in(orga)]
  end

  def immersive_organizations_with_content_at(path_item, current = Organization.current)
    immersive_without_usage = immersive_organizations_for(current)
    return immersive_without_usage unless path_item.present?

    immersive_with_usage = immersive_without_usage.select { |it| path_item.content_used_in? it }
    immersive_with_usage.empty? ? immersive_without_usage : immersive_with_usage
  end

  ## API Exposure

  def to_param
    uid
  end

  class_methods do
    def profile_fields
      [:first_name, :last_name, :gender, :birthdate]
    end
  end

  private

  def immersive_organizations_for(organization)
    return [] unless organization.immersible?

    student_granted_organizations.select { |it| organization.immersed_in?(it) }
  end
end
