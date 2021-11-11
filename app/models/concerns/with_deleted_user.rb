module WithDeletedUser
  def self.prepended(base)
    super
    base.before_destroy :forbid_destroy!, if: :deleted_user?
    base.extend ClassMethods
  end

  def deleted_user?
    self == User.deleted_user
  end

  def abbreviated_name
    return super unless deleted_user?

    I18n.t(:deleted_user, locale: (Organization.current.locale rescue 'en'))
  end

  module ClassMethods
    def deleted_user
      @deleted_user ||= User.create_with(@buried_profile).find_or_create_by(uid: 'deleted:shibi')
    end
  end

  private

  def forbid_destroy!
    raise '"Deleted User" shibi cannot be destroyed'
  end
end
