require "application_system_test_case"

class ProjectsTest < ApplicationSystemTestCase
  test "a visitor can see the favourites and open a project" do
    visit root_path

    assert_text "Current favourites"
    assert_text "Latest projects"

    click_on "Krazoom", match: :first

    assert_selector "h1", text: "Krazoom"
    assert_text "FACT SHEET"
    assert_text "Panel mode"
  end

  test "the type filter narrows the project list" do
    visit projects_path

    assert_text "Krazoom"
    click_on "CLI Tool"

    assert_text "smith"
    assert_no_text "Krazoom"
  end

  test "every project type is named in the legend" do
    visit root_path

    ProjectKind.all.each { |kind| assert_text kind.label }
  end
end
