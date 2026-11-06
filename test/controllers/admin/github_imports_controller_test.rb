require "test_helper"

class Admin::GithubImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the form renders" do
    get new_admin_github_import_path

    assert_response :success
  end

  test "a malformed repository name is reported rather than raised" do
    # No token is configured in test, so the client refuses before any network call.
    post admin_github_imports_path, params: { repo: "not-a-repo" }

    assert_response :unprocessable_content
    assert_match "not-a-repo", response.body
  end
end
