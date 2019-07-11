module Mumuki::Domain::Store

  ## This Store enables importing content
  ## from Bibliotheca API
  class Bibliotheca < Mumukit::Sync::Store::Base
    include Mumukit::Sync::Store::WithWrappedLanguage
    include Mumukit::Sync::Store::WithFilteredId

    def initialize(bibliotheca_bridge)
      @bibliotheca_bridge = bibliotheca_bridge
    end

    def sync_keys
      %w(guide topic book).flat_map do |kind|
        @bibliotheca_bridge
          .send(kind.as_variable_name.pluralize)
          .map { |it| Mumukit::Sync.key kind, it['slug']  }
      end
    end

    def do_read(sync_key)
      @bibliotheca_bridge.send(sync_key.kind.as_variable_name, sync_key.id)
    end

    def write_resource!(*)
      Mumukit::Sync::Store.read_only!
    end
  end
end
