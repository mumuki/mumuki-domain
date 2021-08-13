module Organization::Status

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
      Organization::Status::Disabled.new self
    elsif in_preparation?
      Organization::Status::InPreparation.new self
    else
      Organization::Status::Enabled.new self
    end
  end

end
