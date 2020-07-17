module WithTargetVisualIdentity
  extend ActiveSupport::Concern

  included do
    enum target_visual_identity: [:grown_ups, :kids]
  end

  class_methods do
    def with_current_visual_identity
      where(target_visual_identity: Organization.current.target_visual_identity)
    end
  end
end
