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
    authorization_request.update! status: authorization_status_for(authorization_request)
  end

  def authorization_status_for(authorization_request)
    meets_authorization_criteria?(authorization_request) ? :approved : :rejected
  end

  def self.parse(type, value)
    parse_criterion_type(type, value)
  end

  def self.parse_criterion_type(type, value)
    "ExamRegistration::AuthorizationCriterion::#{type.camelize}".constantize.new(value)
  rescue
    raise "Invalid criterion type #{type}"
  end

  def meets_authorization_criteria?(authorization_request)
    meets_criterion? authorization_request.user, authorization_request.organization
  end

  def authorization_criteria_matcher
    criterion_matcher
  end
end

class ExamRegistration::AuthorizationCriterion::None < ExamRegistration::AuthorizationCriterion
  def initialize(_)
    @value = nil
  end

  def valid?
    !value
  end

  def meets_criterion?(_user, _organization)
    true
  end

  def criterion_matcher
    {}
  end
end

class ExamRegistration::AuthorizationCriterion::PassedExercises < ExamRegistration::AuthorizationCriterion
  def valid?
    value.positive?
  end

  def meets_criterion?(user, organization)
    user.passed_submissions_count_in(organization) >= value
  end

  def criterion_matcher
    { 'stats.passed': { '$gte': value.to_f } }
  end
end
