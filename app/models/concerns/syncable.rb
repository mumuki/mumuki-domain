# Mixin for objects that may
# be treated as `Mumukit::Sync` resources
module Syncable
  extend ActiveSupport::Concern

  # Generates a sync key
  #
  # :warning: This method is required by `Mumukit::Sync::Syncer#import!`
  def sync_key
    Mumukit::Sync.key sync_key_kind, RID
  end

  # Updates this object with the provided
  # resource-hash. Fields not present on it are not modified
  #
  # :warning: This method is required by
  #
  # * `Mumukit::Sync::Syncer#import!`
  # * `Mumukit::Sync::Syncer#import_all!`
  # * `Mumukit::Sync::Syncer#locate_and_import!`
  required :import_from_resource_h!

  # Generates a resource-hash representation
  #
  # :warning: This method is required by
  #
  # * `Mumukit::Sync::Syncer#export!`
  # * `Mumukit::Sync::Syncer#locate_and_export!`
  required :to_resource_h

  private

  def sync_key_kind
    self.class
  end

  def sync_key_id
    self[self.class.sync_key_id_field]
  end

  class_methods do
    # The name of the field used as id with `Mumukit::Sync#key`
    required :sync_key_id_field

    # :warning: This method is required by
    #
    # * `Mumukit::Sync::Syncer#import_all!`
    # * `Mumukit::Sync::Syncer#locate_and_import!`
    # * `Mumukit::Sync::Syncer#locate_and_export!`
    def locate_resource(sync_key_id)
      find_or_initialize_by(sync_key_id_field => sync_key_id)
    end

    # `locate_resource` is a helpful method that can be used
    # outside the `Mumukit::Sync` context, thus this mixin provide
    # a shorter alias
    alias_method :locate, :locate_resource

    # Locates and imports a resource, extracting
    # its key directly from the resource-hash.
    #
    # This class-message is not required by `Mumukit::Sync` but it is exposed
    # for convenience when needing to import resources for whom we already
    # have a resource-hash representation and we don't need to fetch
    # them from a `Mumukit::Sync::Store`.
    def import_from_resource_h!(resource_h)
      locate_resource(extract_sync_key_id(resource_h)).tap do |it|
        it.import_from_resource_h! resource_h
      end
    end

    def extract_sync_key_id(resource_h)
      resource_h[sync_key_id_field]
    end
  end
end
