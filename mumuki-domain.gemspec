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

  s.add_dependency "rails", "~> 5.1.6"

  s.add_dependency 'mumukit-auth', '~> 7.6'
  s.add_dependency 'mumukit-assistant', '~> 0.1'
  s.add_dependency 'mumukit-bridge', '~> 4.0'
  s.add_dependency 'mumukit-content-type', '~> 1.7'
  s.add_dependency 'mumukit-core', '~> 1.13'
  s.add_dependency 'mumukit-directives', '~> 0.5'
  s.add_dependency 'mumukit-randomizer', '~> 1.0'
  s.add_dependency 'mumukit-platform', '~> 5.1'
  s.add_dependency 'mumukit-sync', '~> 1.0'
  s.add_dependency 'mumukit-login', '~> 7.0'

  s.add_dependency 'mulang', '~> 5.0'
  s.add_dependency 'mumukit-inspection', '~> 5.0'

  s.add_development_dependency 'pg', '~> 0.18.0'
  s.add_development_dependency 'mumukit-login', '~> 7.0'
end

