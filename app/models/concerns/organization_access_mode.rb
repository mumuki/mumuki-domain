module OrganizationAccessMode

  class Base
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def validate_active!
    end
  end

  class Full < Base
  end

  class ReadOnly < Base
    def initialize(user, *global_scopes, **specific_scopes)
      super user
      @scopes = global_scopes.map { |scope| [scope, :all] }.to_h.merge specific_scopes
    end
  end

  class ComingSoon < Base
    def validate_active!
      raise Mumuki::Domain::UnpreparedOrganizationError
    end
  end

  class Forbidden < Base
    def validate_active!
      raise Mumuki::Domain::ForbiddenError unless Organization.current.public? || !user
    end
  end
end