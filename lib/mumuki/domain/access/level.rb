module Mumuki::Domain::Access::Level
  PRIORITIES = [:hidden, :disabled, :enabled]

  def self.sort(visibilities)
    visibilities.sort_by  { |it| PRIORITIES.index it }
  end

  def self.min(visibilities)
    sort(visibilities).first || :enabled
  end
end
