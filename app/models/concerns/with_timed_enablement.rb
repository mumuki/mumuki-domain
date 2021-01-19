module WithTimedEnablement
  extend ActiveSupport::Concern

  def enabled?
    enabled_range.cover? DateTime.current
  end

  def enabled_range
    start_time..end_time
  end
end
