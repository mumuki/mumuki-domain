module WithTargetAudience
  extend ActiveSupport::Concern

  included do
    enum target_audience: [:grown_ups, :primary, :kindergarten]
  end

  def kids?
    target_audience.to_sym.in? [:primary, :kindergarten]
  end

  class_methods do
    def with_current_audience_for(user)
      where(target_audience: user.current_audience)
    end
  end
end
