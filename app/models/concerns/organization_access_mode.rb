module OrganizationAccessMode

  class Base
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
  end

  class Full < Base
    def profile_here?
      true
    end
  end

  class ReadOnly < Base
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

  class ComingSoon < Base
    def validate_active!
      raise Mumuki::Domain::UnpreparedOrganizationError
    end

    def faqs_here?
      false
    end

    def profile_here?
      false
    end
  end

  class Forbidden < Base
    def validate_active!
      raise Mumuki::Domain::ForbiddenError unless Organization.current.public? || !user
    end

    def faqs_here?
      false
    end

    def profile_here?
      false
    end
  end
end