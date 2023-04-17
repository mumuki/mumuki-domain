$:.push File.expand_path("../lib", __FILE__)

require "mumuki/domain/version"

Gem::Specification.new do |s|
  s.name        = "mumuki-domain"
  s.version     = Mumuki::Domain::VERSION
  s.authors     = ["Franco Leonardo Bulgarelli"]
  s.email       = ["franco@mumuki.org"]
  s.homepage    = "https://mumuki.org"
  s.summary     = "Mumuki Platform's Domain Model"
  s.description = "Mumuki Platform's Domain Model"
  s.license     = "AGPL-3.0"

  s.files = Dir["{app,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 7.0.0"

  s.add_dependency  'email_validator', '~> 1.6'

  s.add_dependency 'mumukit-auth', '~> 7.11'
  s.add_dependency 'mumukit-assistant', '~> 0.2'
  s.add_dependency 'mumukit-bridge', '~> 4.3'
  s.add_dependency 'mumukit-content-type', '~> 1.11'
  s.add_dependency 'mumukit-core', '~> 1.20'
  s.add_dependency 'mumukit-directives', '~> 0.5'
  s.add_dependency 'mumukit-randomizer', '~> 1.2'
  s.add_dependency 'mumukit-platform', '~> 7.0'
  s.add_dependency 'mumukit-sync', '~> 1.0'
  s.add_dependency 'mumukit-login', '~> 7.0'

  s.add_dependency 'mulang', '~> 6.12'
  s.add_dependency 'mumukit-inspection', '~> 6.0'

  s.add_development_dependency 'sprockets', '~> 3.7'
  s.add_development_dependency 'pg', '~> 1.0'
  s.add_development_dependency 'bundler', '~> 2.0'

  s.required_ruby_version = '>= 3.0'
end
