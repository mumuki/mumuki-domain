module WithSoftDeletion
  extend ActiveSupport::Concern

  included do
    enum deletion_motive: %i(self_deleted inappropriate_content shares_solution discloses_personal_information)
    belongs_to :deleted_by, class_name: 'User', optional: true
  end

  def soft_delete!(motive, deleter)
    update! deletion_motive: motive, deleted_by: deleter, deleted_at: Time.current
  end

  def deleted?
    deleted_at.present?
  end
end
