require "test_helper"

class Github::RepositorySyncTest < ActiveSupport::TestCase
  # A stand-in for Github::Client that returns canned Sawyer-like resources.
  class FakeClient
    def initialize(repository:, releases: [])
      @repository = repository
      @releases = releases
    end

    def repository(_repo) = @repository
    def releases(_repo, **) = @releases
  end

  def resource(attributes)
    Sawyer::Resource.new(Sawyer::Agent.new("https://api.github.com"), attributes)
  end

  def repository(**overrides)
    resource({
      description: "A native comic reader for macOS, from GitHub.",
      language: "Swift",
      homepage: "https://krazoom.app/",
      html_url: "https://github.com/webmatze/krazoom",
      stargazers_count: 412,
      pushed_at: Time.utc(2026, 11, 4, 9, 0),
      archived: false,
      license: { spdx_id: "MIT" }
    }.merge(overrides))
  end

  def release(**overrides)
    resource({
      id: 91000,
      tag_name: "v1.3.0",
      name: "Reading lists",
      body: "Adds reading lists.",
      draft: false,
      published_at: Time.utc(2026, 11, 4, 10, 0),
      created_at: Time.utc(2026, 11, 4, 10, 0),
      html_url: "https://github.com/webmatze/krazoom/releases/tag/v1.3.0",
      assets: []
    }.merge(overrides))
  end

  def sync(project, **client_args)
    Github::RepositorySync.new(project, client: FakeClient.new(**client_args)).call
  end

  test "fills repository facts and stars" do
    project = projects(:pagebee)
    project.update!(github_repo: "webmatze/pagebee")

    sync(project, repository: repository)

    assert_equal "A native comic reader for macOS, from GitHub.", project.reload.tagline
    assert_equal "Swift", project.tech_stack
    assert_equal "MIT", project.license
    assert_equal 412, project.github_stars
    assert_equal Time.utc(2026, 11, 4, 9, 0), project.last_activity_at
    assert_not_nil project.github_synced_at
  end

  test "a locked field with hand-written copy survives the sync" do
    project = projects(:krazoom)
    project.lock!(:tagline)

    sync(project, repository: repository)

    assert_equal "A native comic reader for macOS.", project.reload.tagline
    assert_equal "Swift", project.tech_stack, "unlocked fields still update"
  end

  test "a locked but blank field is still filled" do
    project = projects(:krazoom)
    project.update!(license: nil, locked_fields: %w[ license ])

    sync(project, repository: repository)

    assert_equal "MIT", project.reload.license
  end

  test "German copy is never touched" do
    project = projects(:krazoom)

    sync(project, repository: repository)

    assert_equal "Ein nativer Comic-Reader für macOS.", project.reload.translation_for(:de)["tagline"]
  end

  test "releases become updates" do
    project = projects(:krazoom)

    assert_difference -> { project.updates.count }, 1 do
      sync(project, repository: repository, releases: [ release ])
    end

    update = project.updates.find_by(github_release_id: 91000)
    assert_equal "Reading lists", update.title
    assert_equal "v1.3.0", update.version
    assert_equal Date.new(2026, 11, 4), update.released_on
    assert update.released?
    assert update.from_github?
  end

  test "drafts are skipped" do
    project = projects(:krazoom)

    assert_no_difference -> { project.updates.count } do
      sync(project, repository: repository, releases: [ release(draft: true) ])
    end
  end

  test "a release syncs again without duplicating the update" do
    project = projects(:krazoom)

    sync(project, repository: repository, releases: [ release ])
    assert_no_difference -> { project.updates.count } do
      sync(project, repository: repository, releases: [ release(name: "Reading lists, fixed") ])
    end

    assert_equal "Reading lists, fixed", project.updates.find_by(github_release_id: 91000).title
  end

  test "release assets become downloads, newest one featured" do
    project = projects(:krazoom)
    asset = { name: "Krazoom-1.3.0.dmg", size: 15_000_000,
              browser_download_url: "https://github.com/webmatze/krazoom/releases/download/v1.3.0/Krazoom-1.3.0.dmg" }

    sync(project, repository: repository, releases: [ release(assets: [ asset ]) ])

    download = project.downloads.find_by(url: asset[:browser_download_url])
    assert_equal "dmg", download.file_type
    assert_equal "v1.3.0", download.version
    assert download.featured?
    assert_not project_downloads(:krazoom_dmg).reload.featured?, "the old download loses the primary flag"
  end

  test "an archived repository sets the status" do
    project = projects(:krazoom)

    sync(project, repository: repository(archived: true))

    assert_equal "archived", project.reload.status
  end

  test "a project without a repository raises" do
    assert_raises Github::Error do
      sync(projects(:pagebee), repository: repository)
    end
  end

  test "a client error is recorded on the project" do
    project = projects(:krazoom)
    failing = Class.new do
      def repository(_repo) = raise(Github::Error, "Repository not found")
    end.new

    assert_raises Github::Error do
      Github::RepositorySync.new(project, client: failing).call
    end

    assert_equal "Repository not found", project.reload.github_sync_error
  end
end
