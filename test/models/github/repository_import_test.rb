require "test_helper"

class Github::RepositoryImportTest < ActiveSupport::TestCase
  class FakeClient
    def repository(_repo)
      Sawyer::Resource.new(Sawyer::Agent.new("https://api.github.com"),
        html_url: "https://github.com/webmatze/stunt_driver_3d", archived: false)
    end

    def releases(_repo, **) = []
  end

  test "turns underscores in the repository name into a valid slug" do
    project = Github::RepositoryImport.new("webmatze/stunt_driver_3d", client: FakeClient.new).call

    assert_equal "Stunt Driver 3d", project.name
    assert_equal "stunt-driver-3d", project.slug
  end
end
