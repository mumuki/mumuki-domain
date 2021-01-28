module WithPreferences
  extend ActiveSupport::Concern

  included do
    composed_of :preferences, mapping: %w(uppercase_mode uppercase_mode), constructor: :from_attributes
  end
end