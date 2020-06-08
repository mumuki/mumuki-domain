module Container
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

  def progress_for(user, organization=Organization.current)
    content.progress_for(user, organization)
  end

  private

  # Generally we are calling progress_for for each sibling. That method needs the
  # content. With this includes call we're avoiding the N + 1 queries.
  def siblings
    super.includes(associated_content_name)
  end

  def destroy_usages!
    Usage.destroy_usages_for self
  end
end
