class Mumuki::Domain::ProgressTransfer::Copy < Mumuki::Domain::ProgressTransfer::Base
  def transfer_type
    :copy
  end

  def do_transfer!
    progress_item._copy_to!(destination_organization)
  end
end
