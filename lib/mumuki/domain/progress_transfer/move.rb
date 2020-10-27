class Mumuki::Domain::ProgressTransfer::Move < Mumuki::Domain::ProgressTransfer::Base
  def transfer_type
    :move
  end

  def pre_transfer!
    super
    progress_item.dirty_parent_by_submission!
  end

  def do_transfer!
    progress_item._move_to!(destination_organization)
  end
end
