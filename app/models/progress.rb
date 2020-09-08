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

  def copy_to!(organization)
    dup.transfer_to!(organization)
  end

  def transfer_to!(organization)
    relocate_on!(organization)
    save!
    delete_duplicates!
    self
  end

  alias_method :move_to!, :transfer_to!

  def relocate_on!(organization)
    assign_attributes organization: organization, parent: nil
  end

  def duplicates
    self.class.where(duplicates_key).where.not(id: id)
  end

  def has_duplicates?
    duplicates.present?
  end

  def delete_duplicates!
    duplicates.delete_all
  end
end
