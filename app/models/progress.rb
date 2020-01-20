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
end
