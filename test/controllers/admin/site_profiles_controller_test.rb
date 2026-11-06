require "test_helper"

class Admin::SiteProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the form renders" do
    get edit_admin_site_profile_path

    assert_response :success
    assert_select "textarea[name=?]", "site_profile[translations][de][hero_intro]"
  end

  test "updates the copy and the accent colour" do
    patch admin_site_profile_path, params: { site_profile: {
      hero_headline: "Things I build after work.",
      accent_color: "#FFB35C",
      translations: { de: { hero_headline: "Dinge, die ich nach der Arbeit baue." } }
    } }

    profile = SiteProfile.current
    assert_equal "Things I build after work.", profile.hero_headline
    assert_equal "#FFB35C", profile.accent_color
    I18n.with_locale(:de) { assert_equal "Dinge, die ich nach der Arbeit baue.", profile.localized_hero_headline }
  end

  test "rejects a colour that is not a hex value" do
    patch admin_site_profile_path, params: { site_profile: { accent_color: "chartreuse" } }

    assert_response :unprocessable_content
  end
end
