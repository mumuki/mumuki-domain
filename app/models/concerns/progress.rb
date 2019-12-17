module Progress
  extend ActiveSupport::Concern

  included do
    before_save :parent, unless: :parent_id?
    belongs_to :parent, class_name: 'Indicator', optional: true
  end

  def parent
    super || assign_attributes(parent: parent_content&.progress_for(user, organization))
    super
  end

  def dirty_parent!
    parent&.dirty!
  end
end
