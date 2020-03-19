module WithAccessRules
  extend ActiveSupport::Concern

  included do
    has_many :access_rules, as: :owner
  end

  def add_access_rule!(rule)
    access_rules << rule
  end

  def recompile_access_config!
    return unless access_config

    config = Mumuki::Domain::Access::Config.new(access_config, self)
    config.compile!
    access_rules = config.rules
  end

  def configure_access!(config)
    self.access_config = config
    self.recompile_access_config!
  end
end
