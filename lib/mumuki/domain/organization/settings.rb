class Mumuki::Domain::Organization::Settings < Mumukit::Platform::Model
  include Mumukit::Login::LoginSettingsHelpers

  model_attr_accessor :disabled_from,
                      :embeddable?,
                      :feedback_suggestions_enabled?,
                      :forum_discussions_minimal_role,
                      :forum_enabled?,
                      :forum_only_for_trusted?,
                      :gamification_enabled?,
                      :immersive?,
                      :in_preparation_until,
                      :login_methods,
                      :login_provider,
                      :login_provider_settings,
                      :public?,
                      :raise_hand_enabled?,
                      :report_issue_enabled?,
                      :email_verification_policy

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

  def email_verification_policy
    Mumuki::Domain::Organization::EmailVerificationPolicy.parse(@email_verification_policy)
  end
end
