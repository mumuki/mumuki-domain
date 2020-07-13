module WithLayout
  extend ActiveSupport::Concern

  included do
    enum layout: [:input_right, :input_bottom, :input_primary, :input_kindergarten]
  end

  def input_kids?
    input_primary? || input_kindergarten?
  end
end
