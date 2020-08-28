class Mumuki::Domain::Organization::Profile < Mumukit::Platform::Model
  LOCALES = Mumukit::Platform::Locale::SPECS

  model_attr_accessor :logo_url,
                      :banner_url,
                      :favicon_url,
                      :breadcrumb_image_url,
                      :open_graph_image_url,
                      :locale,
                      :description,
                      :contact_email,
                      :terms_of_service,
                      :community_link,
                      :errors_explanations,
                      :welcome_email_template

  def locale_json
    locale_h.to_json
  end

  def locale_h
    Mumukit::Platform::Locale::SPECS[locale]
  end

  def logo_url
    @logo_url ||= 'https://mumuki.io/logo-alt-large.png' # Best image size: 350x75
  end

  def banner_url
    @banner_url || logo_url  # Best image size: 350x75
  end

  def favicon_url
    @favicon_url ||= '/favicon.ico'  # Best image size: 16x16, 32x32 or 48x48
  end

  def open_graph_image_url
    @open_graph_image_url ||= Mumukit::Platform.application.url_for("logo-alt.png")  # Best image size: 256x256
  end
end
