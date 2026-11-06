require "application_system_test_case"

class AdminProjectsTest < ApplicationSystemTestCase
  setup do
    visit new_session_path
    fill_in "email_address", with: users(:one).email_address
    fill_in "password", with: "password"
    click_on "Sign in"

    # Wait for the redirect to land before the test navigates on.
    assert_current_path root_path
  end

  test "creating a project and publishing it puts it on the home page" do
    visit new_admin_project_path

    fill_in "Name", with: "Honigflug"
    select "Game", from: "Type"
    fill_in "Tagline", with: "A bee simulation for the DragonRuby Game Toolkit."
    check "Published"
    click_on "Save project"

    assert_text "Project created."

    visit root_path
    assert_text "Honigflug"
    assert_text "A bee simulation for the DragonRuby Game Toolkit."
  end

  test "the Add button appends another feature row" do
    visit edit_admin_project_path(projects(:krazoom))

    within_fieldset "Features" do
      rows = all("[data-nested-form-target='row']").size
      click_on "Add"
      assert_selector "[data-nested-form-target='row']", count: rows + 1
    end
  end

  test "German copy entered in the admin shows on the German page" do
    visit edit_admin_project_path(projects(:pagebee))

    fill_in "Tagline (German)", with: "No-Code-Baukasten für Webseiten."
    click_on "Save project"

    assert_text "Project updated."

    visit project_path(projects(:pagebee), locale: :de)
    assert_text "No-Code-Baukasten für Webseiten."
  end
end
