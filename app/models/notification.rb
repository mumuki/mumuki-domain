class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :target, polymorphic: true

  def self.mark_as_read!(target)
    find_by!(target: target).update(read: true)
  end
end
