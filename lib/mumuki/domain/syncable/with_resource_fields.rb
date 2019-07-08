module Mumuki::Domain::Syncable
  ## Syncable objects that also declare
  ## a `resource_fields` method can define `resource_h`
  ## and `self.slice_resource_h` based on it.
  module WithResourceFields
    extend ActiveSupport::Concern

    def to_resource_h
      self.class.resource_fields.map { |it| [it, send(it)] }.to_h.compact
    end

    class_methods do
      def slice_resource_h(resource_h)
        resource_h.slice(*resource_fields)
      end
    end
  end
end
