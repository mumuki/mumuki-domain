class Mumuki::Domain::Organization::Settings < Mumukit::Platform::Model
  include Mumukit::Login::LoginSettingsHelpers

  model_attr_accessor :login_methods,
                      :login_provider,
                      :login_provider_settings,
                      :forum_discussions_minimal_role,
                      :raise_hand_enabled?,
                      :feedback_suggestions_enabled?,
                      :public?,
                      :embeddable?,
                      :immersive?,
                      :forum_enabled?,
                      :report_issue_enabled?,
                      :archiving_enabled?,
                      :archive_from,
                      :unavailable?,
                      :unavailable_to

  def private?
    !public?
  end

  def login_methods
    @login_methods ||= ['user_pass']
  end

  def forum_discussions_minimal_role
    (@forum_discussions_minimal_role || 'student').to_sym
  end

  def archived?
    archiving_enabled? && archive_from.to_datetime < DateTime.now
  end

  def disabled?
    unavailable? && unavailable_to.to_datetime > DateTime.now
  end
end
