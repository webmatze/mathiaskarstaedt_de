class Admin::SiteProfilesController < Admin::BaseController
  before_action :set_site_profile

  def edit
  end

  def update
    if @site_profile.update(site_profile_params)
      redirect_to edit_admin_site_profile_path, notice: t("admin.flash.profile_updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private
    def set_site_profile
      @site_profile = SiteProfile.current
    end

    def site_profile_params
      params.expect(site_profile: [
        :terminal_prompt, :hero_headline, :hero_intro, :about_headline, :about_body,
        :skills, :accent_color, :imprint_body, :privacy_body,
        { translations: [ { de: SiteProfile.translatable_fields.map(&:to_sym) } ] }
      ])
    end
end
