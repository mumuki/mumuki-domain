module WithDiscussionStatus
  extend ActiveSupport::Concern

  included do
    enums = [:opened, :closed, :solved, :pending_review]
    serialize_enum status: enums, class: Mumuki::Domain::DiscussionStatus
    validates_presence_of :status
    scope :by_status, -> (status) { where(status: status) }
  end

  delegate :closed?, :opened?, :solved?, :pending_review?, :reachable_statuses, to: :status
end
