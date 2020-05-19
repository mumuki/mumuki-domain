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
                      :disabled_from,
                      :in_preparation_until

  def private?
    !public?
  end

  def login_methods
    @login_methods ||= ['user_pass']
  end

  def forum_discussions_minimal_role
    (@forum_discussions_minimal_role || 'student').to_sym
  end

  def disabled?
    disabled_from.present? && disabled_from.to_datetime < DateTime.now
  end

  def in_preparation?
    in_preparation_until.present? && in_preparation_until.to_datetime > DateTime.now
  end
end
