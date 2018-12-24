module WithExpectations
  extend ActiveSupport::Concern

  included do
    serialize :expectations, Array
    validate :ensure_expectations_format
  end

  def expectations_yaml
    self.expectations.to_yaml
  end

  def expectations_yaml=(yaml)
    self.expectations = YAML.load yaml
  end

  def expectations=(expectations)
    self[:expectations] = expectations.map(&:stringify_keys)
  end

  def ensure_expectations_format
    errors.add :expectations,
               :invalid_format unless expectations.to_a.all? { |it| Mumukit::Expectation.valid? it }
  end
end
