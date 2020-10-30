module WithMedal
  extend ActiveSupport::Concern

  included do
    belongs_to :medal, optional: true
  end
end
