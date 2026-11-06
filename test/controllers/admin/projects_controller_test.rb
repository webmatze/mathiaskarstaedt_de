require "test_helper"

class Admin::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the admin is closed without a session" do
    reset!

    get admin_projects_path
    assert_redirected_to new_session_path
  end

  test "the index lists drafts alongside published projects" do
    get admin_projects_path

    assert_response :success
    assert_match projects(:draft).name, response.body
    assert_match projects(:krazoom).name, response.body
  end

  test "the index shows how complete the German translation is" do
    get admin_projects_path

    assert_match "2/2", response.body, "Krazoom has both fields translated"
    assert_match "0/2", response.body, "PageBee has none"
  end

  test "the new and edit forms render" do
    get new_admin_project_path
    assert_response :success

    get edit_admin_project_path(projects(:krazoom))
    assert_response :success
    assert_select "textarea[name=?]", "project[translations][de][tagline]"
  end

  test "creates a project" do
    assert_difference -> { Project.count }, 1 do
      post admin_projects_path, params: { project: {
        name: "Honigflug", kind: "game", status: "active", tagline: "A bee simulation."
      } }
    end

    project = Project.find_by(slug: "honigflug")
    assert_redirected_to edit_admin_project_path(project)
    assert_equal "A bee simulation.", project.tagline
    assert_not project.published?, "a new project starts as a draft"
  end

  test "an invalid project comes back with its errors" do
    assert_no_difference -> { Project.count } do
      post admin_projects_path, params: { project: { name: "", kind: "game" } }
    end

    assert_response :unprocessable_content
    assert_match "Name", response.body
  end

  test "saves German copy into the translations column" do
    patch admin_project_path(projects(:pagebee)), params: { project: {
      translations: { de: { tagline: "No-Code-Baukasten für Webseiten." } }
    } }

    assert_equal "No-Code-Baukasten für Webseiten.", projects(:pagebee).reload.translation_for(:de)["tagline"]
  end

  test "clearing a German field falls back to English again" do
    patch admin_project_path(projects(:krazoom)), params: { project: {
      translations: { de: { tagline: "", description: "" } }
    } }

    project = projects(:krazoom).reload
    assert_equal 0, project.translated_field_count(:de)
    I18n.with_locale(:de) { assert_equal "A native comic reader for macOS.", project.localized_tagline }
  end

  test "adds a feature with its German copy through nested attributes" do
    project = projects(:pagebee)

    assert_difference -> { project.features.count }, 1 do
      patch admin_project_path(project), params: { project: {
        features_attributes: { "0" => {
          title: "Section library", body: "Pick a section, adjust it, publish.",
          translations: { de: { title: "Sektions-Bibliothek" } }
        } }
      } }
    end

    feature = project.features.reload.last
    assert_equal "Section library", feature.title
    I18n.with_locale(:de) { assert_equal "Sektions-Bibliothek", feature.localized_title }
  end

  test "removes a nested record" do
    feature = project_features(:formats)

    assert_difference -> { projects(:krazoom).features.count }, -1 do
      patch admin_project_path(projects(:krazoom)), params: { project: {
        features_attributes: { "0" => { id: feature.id, _destroy: "1" } }
      } }
    end
  end

  test "locks a field against the GitHub sync" do
    patch admin_project_path(projects(:krazoom)), params: { project: { locked_fields: [ "", "tagline" ] } }

    project = projects(:krazoom).reload
    assert project.locked?("tagline")
    assert_equal %w[ tagline ], project.locked_fields
  end

  test "deletes a project" do
    assert_difference -> { Project.count }, -1 do
      delete admin_project_path(projects(:draft))
    end

    assert_redirected_to admin_projects_path
  end

  test "sync now queues the job" do
    assert_enqueued_with job: GithubSyncJob, args: [ projects(:krazoom) ] do
      post admin_project_github_sync_path(projects(:krazoom))
    end
  end
end
