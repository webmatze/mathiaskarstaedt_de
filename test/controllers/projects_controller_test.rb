require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  test "the index lists the published projects" do
    get projects_path

    assert_response :success
    assert_select "a[href=?]", project_path(projects(:krazoom))
    assert_select "a[href=?]", project_path(projects(:draft)), count: 0
  end

  test "the kind filter narrows the list without JavaScript" do
    get projects_path(kind: "cli")

    assert_response :success
    assert_select "a[href=?]", project_path(projects(:smith))
    assert_select "a[href=?]", project_path(projects(:krazoom)), count: 0
    assert_select "a[aria-current=true]", text: "CLI Tool"
  end

  test "an empty kind shows the empty state" do
    get projects_path(kind: "mobile")

    assert_response :success
    assert_match "Nothing new in this category", response.body
  end

  test "an unknown kind shows everything rather than nothing" do
    get projects_path(kind: "nonsense")

    assert_select "a[href=?]", project_path(projects(:krazoom))
  end

  test "the detail page shows the fact sheet, features, timeline and download" do
    get project_path(projects(:krazoom))

    assert_response :success
    assert_select "h1", text: "Krazoom"
    assert_select "h2", text: "Features"
    assert_select "h3", text: "Panel mode"
    assert_select "h2", text: "Updates"
    assert_select "h3", text: "New: panel mode"
    assert_select "h2", text: "Fact sheet"
    assert_match "Apple Silicon", response.body
    assert_match "Related projects", response.body
  end

  test "the detail page renders in German" do
    get project_path(projects(:krazoom), locale: :de)

    assert_response :success
    assert_select "h2", text: "Funktionen"
    assert_select "h3", text: "Panel-Modus"
    assert_select "h2", text: "Steckbrief"
    assert_match "Öffnet CBZ, CBR, PDF und Bildordner ohne Importschritt.", response.body
    assert_no_match(/translation missing/, response.body)
  end

  test "a draft is not reachable" do
    get project_path(projects(:draft))

    assert_response :not_found
  end
end
