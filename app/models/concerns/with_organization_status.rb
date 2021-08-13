module WithOrganizationStatus

  def status
    @status ||= _status
  end

  def access_mode(user)
    status.access_mode(user)
  end

  def validate_active!
    status.validate!
  end

  def validate_active_for!(user)
    status.validate!(user)
    access_mode(user).validate_active!
  end

  private

  def _status
    if disabled?
      WithOrganizationStatus::Disabled.new self
    elsif in_preparation?
      @status ||= WithOrganizationStatus::InPreparation.new self
    else
      @status ||= WithOrganizationStatus::Enabled.new self
    end
  end

end
