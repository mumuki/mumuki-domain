module Mumuki::Domain::Helpers::Course
  include Mumukit::Platform::Notifiable

  def platform_class_name
    :Course
  end

  ## API Exposure

  def to_param
    slug
  end
end
