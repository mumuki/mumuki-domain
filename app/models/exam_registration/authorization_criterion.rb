class ExamRegistration::AuthorizationCriterion
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def type
    self.class.name.demodulize.underscore
  end

  def as_json
    { type: type, value: value }
  end

  def ensure_valid!
    raise "Invalid criterion value #{value} for #{type}" unless valid?
  end

  def process_request!(authorization_request)
    authorization_request.update! status: authorization_status_for(authorization_request.user)
  end

  def authorization_status_for(user)
    enabled_for?(user) ? :approved : :rejected
  end

  def self.parse(type, value)
    parse_criterion_type(type, value)
  end

  def self.parse_criterion_type(type, value)
    "ExamRegistration::AuthorizationCriterion::#{type.camelize}".constantize.new(value)
  rescue
    raise "Invalid criterion type #{type}"
  end
end

class ExamRegistration::AuthorizationCriterion::None < ExamRegistration::AuthorizationCriterion
  def initialize(_)
    @value = nil
  end

  def valid?
    !value
  end

  def enabled_for?(_user)
    true
  end
end

class ExamRegistration::AuthorizationCriterion::PassedExercises < ExamRegistration::AuthorizationCriterion
  def valid?
    value.positive?
  end

  def enabled_for?(user)
    user.passed_submissions_count >= value
  end
end
