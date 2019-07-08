module Mumuki::Domain::Helpers::User
  include Mumukit::Auth::Roles
  include Mumukit::Platform::Notifiable

  ## Permissions

  delegate :has_role?,
           :add_permission!,
           :remove_permission!,
           :has_permission?,
           :has_permission_delegation?,
           :protect!,
           :protect_delegation!,
           :protect_permissions_assignment!,
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
    # the given organization
    define_method role_of do |organization|
      has_permission? role, organization.slug
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
    # for the given slug
    define_method "make_#{role}_of!" do |slug|
      add_permission! role, slug
    end
  end

  ## Profile

  def full_name
    "#{first_name} #{last_name}"
  end

  alias_method :name, :full_name

  def profile_completed?
    [first_name, last_name].all? &:present?
  end

  def to_s
    "#{full_name} <#{email}> [#{uid}]"
  end

  ## Accesible organizations

  def student_granted_organizations
    permissions.student_granted_organizations.map do |org|
      Mumukit::Platform::Organization.find_by_name!(org) rescue nil
    end.compact
  end

  def has_student_granted_organizations?
    student_granted_organizations.present?
  end

  def main_organization
    student_granted_organizations.first
  end

  def has_main_organization?
    student_granted_organizations.length == 1
  end

  def has_immersive_main_organization?
    !!main_organization.try(&:immersive?)
  end

  ## API Exposure

  def to_param
    uid
  end
end
