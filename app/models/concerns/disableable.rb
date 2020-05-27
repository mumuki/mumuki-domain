# The disposable module is a soft-delete helper
# that acts as a thin layer over Discard that:
#
#  * adds `discard!` methods and friends
#  * adds `disable!` method that discards and "buries" the object
#  * adds a `bury!`  hook method that allows further modification of the object after being discarded within disable!
#  * aliases `destroy!` and `destroy` to `disable!`, but still keeps `delete` and friends
#
module Disableable
  extend ActiveSupport::Concern

  included do
    include Discard::Model

    alias_method :enabled?, :kept?
    alias_method :disabled?, :discarded?
  end

  def disable!
    transaction do
      discard!
      bury!
    end
  end

  # override to perform additional
  # post-disable actions
  def bury!
  end

  def ensure_enabled!
    raise Mumuki::Domain::NotFoundError if disabled?
  end

  alias_method :destroy!,  :disable!
  alias_method :destroy,   :disable!
end

