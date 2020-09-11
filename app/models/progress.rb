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
    relocate_on!(organization)
    delete_duplicates!
    save!
    self
  end

  alias_method :_move_to!, :transfer_to!

  %i(copy_to! move_to!).each do |selector|
    define_method(selector) do |organization|
      raise "Transferred progress' content must be available in destination!" unless content_available_in?(organization)
      dirty_parent_by_submission!
      progress_item = send("_#{selector}", organization)
      progress_item.dirty_parent_by_submission!
    end
  end

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
