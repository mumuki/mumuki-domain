class Exam::PassingCriterion

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def type
    self.class.name.demodulize.underscore
  end

  def as_json
    {type: type, value: value}
  end

  def ensure_valid_criterion!
    raise "Invalid criterion value #{value} for #{type}" unless valid_passing_grade?
  end

  def self.parse(type, value)
    parse_criterion_type(type, value).tap(&:ensure_valid_criterion!)
  end

  def self.parse_criterion_type(type, value)
    "Exam::PassingCriterion::#{type.camelize}".constantize.new(value)
  rescue
    raise "Invalid criterion type #{type}"
  end

end

class Exam::PassingCriterion::None < Exam::PassingCriterion
  def initialize(_)
    @value = nil
  end

  def valid_passing_grade?
    !value
  end
end

class Exam::PassingCriterion::Percentage < Exam::PassingCriterion
  def valid_passing_grade?
    value.between? 0, 100
  end
end

class Exam::PassingCriterion::PassedExercises < Exam::PassingCriterion
  def valid_passing_grade?
    value >= 0
  end
end
