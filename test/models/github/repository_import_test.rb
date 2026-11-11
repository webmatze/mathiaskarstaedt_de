require "test_helper"

class Github::RepositoryImportTest < ActiveSupport::TestCase
  class FakeClient
    def repository(repo)
      Sawyer::Resource.new(Sawyer::Agent.new("https://api.github.com"),
        html_url: "https://github.com/#{repo}", archived: false)
    end

    def releases(_repo, **) = []
  end

  class MissingRepositoryClient
    def repository(_repo) = raise(Github::Error, "Repository not found or not visible with this token")
  end

  def import(repo, client: FakeClient.new)
    Github::RepositoryImport.new(repo, client: client).call
  end

  test "turns underscores in the repository name into a valid slug" do
    project = import("webmatze/stunt_driver_3d")

    assert_equal "Stunt Driver 3d", project.name
    assert_equal "stunt-driver-3d", project.slug
  end

  test "leaves no draft behind when GitHub does not know the repository" do
    assert_no_difference -> { Project.count } do
      assert_raises(Github::Error) { import("webmatze/stunt-driver-3d", client: MissingRepositoryClient.new) }
    end
  end

  test "keeps an existing project and records the error when its sync fails" do
    project = projects(:pagebee)
    project.update!(github_repo: "webmatze/pagebee")

    assert_raises(Github::Error) { import("webmatze/pagebee", client: MissingRepositoryClient.new) }

    assert_equal "Repository not found or not visible with this token", project.reload.github_sync_error
  end
end
