require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "the home page shows the hero, the favourites and the latest projects" do
    get root_path

    assert_response :success
    assert_select "h1", text: /Web apps, Mac apps, CLI tools and games/
    assert_select "h2", text: "Current favourites"
    assert_select "h2", text: "Latest projects"
    assert_select "a[href=?]", project_path(projects(:krazoom))
  end

  test "the home page never shows a draft" do
    get root_path

    assert_select "a[href=?]", project_path(projects(:draft)), count: 0
    assert_no_match projects(:draft).name, response.body
  end

  test "the home page lists every project type in the legend" do
    get root_path

    ProjectKind.all.each { |kind| assert_match kind.label, response.body }
  end

  test "the home page renders in German without a missing translation" do
    get root_path(locale: :de)

    assert_response :success
    assert_select "html[lang=?]", "de"
    assert_select "h1", text: /Web-Apps, Mac-Apps, CLI-Tools und Spiele/
    assert_select "h2", text: "Aktuelle Lieblinge"
    assert_match "Ein nativer Comic-Reader für macOS.", response.body
    assert_no_match(/translation missing/, response.body)
  end

  test "an unknown locale falls back to English" do
    get root_path(locale: :fr)

    assert_select "html[lang=?]", "en"
  end

  test "the imprint and privacy pages render" do
    get imprint_path
    assert_response :success
    assert_match "Imprint text.", response.body

    get privacy_path
    assert_response :success
    assert_match "Privacy text.", response.body
  end

  test "the sitemap lists the published projects only" do
    get sitemap_path

    assert_response :success
    assert_match project_url(projects(:krazoom)), response.body
    assert_no_match project_url(projects(:draft)), response.body
  end
end
