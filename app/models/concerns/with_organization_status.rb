module WithOrganizationStatus

  def status
    if disabled?
      @status ||= WithOrganizationStatus::Disabled.new self
    elsif in_preparation?
      @status ||= WithOrganizationStatus::InPreparation.new self
    else
      @status ||= WithOrganizationStatus::Enabled.new self
    end
  end

  def validate_active_for!(user)
    status.validate!(user)
    status.access_mode(user).validate_active!
  end

end
