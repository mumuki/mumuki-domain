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

  %w(copy move).each do |transfer_type|
    define_method "#{transfer_type}_to!" do |organization|
      "Mumuki::Domain::ProgressTransfer::#{transfer_type.camelize}".constantize.new(self, organization).execute!
    end
  end

  def guide_indicator?
    is_a?(Indicator) && content_type == 'Guide'
  end

  def has_duplicates_in?(organization)
    duplicates_in(organization).present?
  end

  def delete_duplicates_in!(organization)
    duplicates_in(organization).delete_all
  end

  private

  def duplicates_in(organization)
    self.class.where(duplicates_key.merge(organization: organization)).where.not(id: id)
  end
end
