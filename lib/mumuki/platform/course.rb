module Mumukit::Platform::Course
  def self.find_by_slug!(slug)
    Mumukit::Platform.course_class.find_by_slug!(slug)
  end
end

require_relative './course/helpers'
