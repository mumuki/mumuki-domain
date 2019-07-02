module Mumukit::Platform::User
  def self.find_by_uid!(uid)
    Mumukit::Platform.user_class.find_by_uid!(uid)
  end
end

require_relative './user/helpers'
