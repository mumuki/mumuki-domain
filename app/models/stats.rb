class Stats
  include ActiveModel::Model

  attr_accessor :passed, :passed_with_warnings, :failed, :pending, :skipped

  def submitted
    passed + passed_with_warnings + failed
  end

  def done?
    missing == 0
  end

  def almost_done?
    missing <= 1
  end

  def almost_but_not_done?
    missing == 1
  end

  def started?
    submitted > 0
  end

  def missing
    failed + pending
  end

  def self.from_statuses(statuses)
    Stats.new(statuses.inject({passed: 0, passed_with_warnings: 0, failed: 0, pending: 0, skipped: 0}) do |accum, status|
      accum[status.group.to_sym] += 1
      accum
    end)
  end
end
