class Mumuki::Domain::ProgressTransfer::Base
  attr_reader *%i(source_organization destination_organization progress_item transferred_item)

  delegate :user, to: :progress_item

  def initialize(progress_item, destination_organization)
    @progress_item = progress_item
    @destination_organization = destination_organization
  end

  def execute!
    ActiveRecord::Base.transaction do
      pre_transfer!
      transfer!
      post_transfer!
    end
  end

  def pre_transfer!
    validate_transferrable!
    @source_organization = progress_item.organization
    progress_item.delete_duplicates_in!(destination_organization)
  end

  def transfer!
    @transferred_item = do_transfer!
  end

  def post_transfer!
    transferred_item.dirty_parent_by_submission!
    notify_transfer!
    transferred_item
  end

  def validate_transferrable!
    raise "Transferred progress' content must be available in destination!" unless progress_item.content_available_in?(destination_organization)
    raise 'User must be student in destination organization' unless user.student_granted_organizations.include?(destination_organization)
    raise 'Transfer only supported for guide indicators' unless progress_item.guide_indicator?
  end

  def notify_transfer!
    Mumukit::Nuntius.notify! 'progress-transfers', { from: source_organization.name, to: destination_organization.name, item_type: progress_item.class.to_s, item_id: progress_item.id, transfer_type: transfer_type }
  end
end
