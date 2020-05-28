# The disposable module is a soft-delete helper that:
#
#  * adds `disable!` method that set a `disabled_at` attribute anden then _buries_ the object
#  * adds a `bury!`  hook method that allows further modification when disabling
#  * aliases `destroy!` and `destroy` to `disable!`, but still keeps `delete` and friends
#
module Disabling
  extend ActiveSupport::Concern

  def disable!
    transaction do
      update_attribute :disabled_at, Time.current
      bury!
    end
  end

  def disabled?
    disabled_at.present?
  end

  def enabled?
    !disabled?
  end

  # override to perform additional
  # post-disable actions
  def bury!
  end

  def ensure_enabled!
    raise Mumuki::Domain::ForbiddenError if disabled?
  end

  alias_method :destroy!,  :disable!
  alias_method :destroy,   :disable!
end

