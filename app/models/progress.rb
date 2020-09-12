class Progress < ApplicationRecord
  self.abstract_class = true

  before_save :parent, unless: :parent_id?
  belongs_to :parent, class_name: 'Indicator', optional: true

  def parent
    assign_attributes(parent: parent_content&.progress_for(user, organization)) unless super
    super
  end

  def dirty_parent_by_submission!
    parent&.dirty_by_submission!
  end

  def _copy_to!(organization)
    dup.transfer_to!(organization)
  end

  def transfer_to!(organization)
    update! organization: organization, parent: nil
    self
  end

  alias_method :_move_to!, :transfer_to!

  def copy_to!(organization)
    validate_transferrable_to!(organization)
    delete_duplicates_in!(organization)
    progress_item = _copy_to!(organization)
    progress_item.dirty_parent_by_submission!
  end

  def move_to!(organization)
    validate_transferrable_to!(organization)
    delete_duplicates_in!(organization)
    dirty_parent_by_submission!
    _move_to!(organization)
    dirty_parent_by_submission!
  end

  def validate_transferrable_to!(organization)
    raise "Transferred progress' content must be available in destination!" unless content_available_in?(organization)
  end

  def has_duplicates_in?(organization)
    duplicates_in(organization).present?
  end

  private

  def duplicates_in(organization)
    self.class.where(duplicates_key.merge(organization: organization)).where.not(id: id)
  end

  def delete_duplicates_in!(organization)
    duplicates_in(organization).delete_all
  end
end
