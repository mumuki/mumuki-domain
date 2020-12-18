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

  def raw_expectations
    self[:expectations]
  end

  def ensure_expectations_format
    errors.add :raw_expectations,
               :invalid_format unless raw_expectations.to_a.all? { |it| Mulang::Expectation.valid? it }
  end
end
