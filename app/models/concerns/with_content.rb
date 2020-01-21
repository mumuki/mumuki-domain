module WithContent
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_usages!
  end

  class_methods do
    def associated_content(content_name)
      belongs_to content_name
      validates_presence_of content_name

      alias_method :content, content_name

      define_method(:associated_content_name) { content_name }
    end
  end

  private

  def destroy_usages!
    Usage.destroy_usages_for self
  end
end
