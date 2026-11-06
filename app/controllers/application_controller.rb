class ApplicationController < ActionController::Base
  include Authentication

  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale

  helper_method :site_profile

  private
    # English is what ships. A locale only comes from the route (params[:locale]),
    # never from the Accept-Language header, so a URL always renders the same page.
    def switch_locale(&action)
      locale = params[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

    def default_url_options
      I18n.locale == I18n.default_locale ? {} : { locale: I18n.locale }
    end

    # The accent colour and the hand-written copy live here; the layout needs it
    # on every page, signed in or not.
    def site_profile
      @site_profile ||= SiteProfile.current
    end
end
