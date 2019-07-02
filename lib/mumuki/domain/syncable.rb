# Mixin for objects that may
# be treated as `Mumukit::Sync` resources
#
# `Syncable` objects also get `Mumukit::Platform::Notifiable` by free
module Mumuki::Domain::Syncable
  extend ActiveSupport::Concern
  include Mumukit::Platform::Notifiable

  # Generates a sync key
  #
  # :warning: This method is required by `Mumukit::Sync::Syncer#import!`
  def sync_key
    Mumukit::Sync.key sync_key_kind, sync_key_id
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

  # :warning: This method is required by `Mumukit::Platform::Notifiable#notify!`
  def platform_class_name
    sync_key_kind.as_module_name
  end

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
      find_or_initialize_by sync_key_id_field => sync_key_id
    end

    # `locate!` is similar to `locate`, but fails instead of creating a
    # a new object when not found
    #
    # This method is not required by `Mumukit::Sync`
    def locate!(sync_key_id)
      find_by! sync_key_id_field => sync_key_id
    rescue ActiveRecord::RecordNotFound
      raise ActiveRecord::RecordNotFound, "Coudn't find #{self.name} with #{sync_key_id_field}:  #{sync_key_id}"
    end

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

require_relative './syncable/with_resource_fields'
