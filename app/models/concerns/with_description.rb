module WithDescription
  extend ActiveSupport::Concern

  included do
    markdown_on :description, skip_sanitization: true
    teaser_on :description
    validates_presence_of :description
  end
end
