class UserMailer < ApplicationMailer
  default from: Rails.configuration.sender_email
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.we_miss_you_notification.subject
  #
  def we_miss_you_reminder(user, weeks)
    @user = user

    mail to: user.email,
         subject: t(:we_miss_you),
         template_name: "#{weeks.ordinalize}_reminder"
  end
end
