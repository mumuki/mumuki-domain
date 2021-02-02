module WithTargetAudience
  extend ActiveSupport::Concern

  included do
    enum target_audience: [:grown_ups, :kids, :kindergarten]
  end

  class_methods do
    def with_current_audience_for(user)
      where(target_audience: user.current_audience)
    end
  end
end
