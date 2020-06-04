class ExamPassingCriterion

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

  def self.parse(type, value)
    passing_criterion = parse_criterion_type(type, value)
    unless passing_criterion.valid_passing_grade?
      raise "Invalid criterion value #{value} for #{type}"
    end
    passing_criterion
  end

  def self.parse_criterion_type(type, value)
    "ExamPassingCriterion::#{type.camelize}".constantize.new(value)
  rescue
    raise "Invalid criterion type #{type}"
  end

end

class ExamPassingCriterion::None < ExamPassingCriterion
  def initialize(_)
    @value = nil
  end

  def valid_passing_grade?
    !value
  end
end

class ExamPassingCriterion::Percentage < ExamPassingCriterion
  def valid_passing_grade?
    value.between? 0, 100
  end
end

class ExamPassingCriterion::PassedExercises < ExamPassingCriterion
  def valid_passing_grade?
    value >= 0
  end
end
