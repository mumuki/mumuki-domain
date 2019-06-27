module Mumukit::Sync::Store

  ## This Store enables importing languages
  ## from Thesaurus API
  class Thesaurus < Mumukit::Sync::Store::Base
    def initialize(thesaurus_bridge)
      @thesaurus_bridge = thesaurus_bridge
    end

    def sync_keys
      @thesaurus_bridge.runners.map { |it| Mumukit::Sync.key(:language, it) }
    end

    def do_read(sync_key)
      return unless sync_key.kind.like? :language
      # the only difference between an `importable_info`
      # and a `resource_h` is the way `runner_url` is named
      Mumukit::Bridge::Runner.new(sync_key.id)
        .importable_info
        .replace_key(:test_runner_url, :runner_url)
    end

    def write_resource!(*)
      Mumukit::Sync::Store.read_only!
    end
  end
end
