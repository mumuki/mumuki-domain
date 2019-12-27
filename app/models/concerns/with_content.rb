module WithContent
  extend ActiveSupport::Concern

  included do
    before_destroy :destroy_usages!
  end

  private

  def destroy_usages!
    Usage.destroy_usages_for self
  end
end
