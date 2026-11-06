require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "published scope hides drafts" do
    assert_not_includes Project.published, projects(:draft)
    assert_includes Project.published, projects(:krazoom)
  end

  test "recent orders by last activity, newest first" do
    assert_equal %w[ secret-thing pagebee smith krazoom ], Project.recent.pluck(:slug)
  end

  test "featured orders by featured position" do
    assert_equal %w[ krazoom smith ], Project.featured.pluck(:slug)
  end

  test "of_kind filters, and ignores an unknown kind" do
    assert_equal [ projects(:smith) ], Project.published.of_kind("cli").to_a
    assert_equal Project.published.to_a, Project.published.of_kind("nonsense").to_a
  end

  test "slug is derived from the name when blank" do
    project = Project.create!(name: "Core Breach", kind: "game")
    assert_equal "core-breach", project.slug
  end

  test "slug must be url safe" do
    project = Project.new(name: "X", slug: "Not A Slug", kind: "game")
    assert_not project.valid?
    assert_includes project.errors[:slug].first, "lowercase"
  end

  test "to_param uses the slug" do
    assert_equal "krazoom", projects(:krazoom).to_param
  end

  test "hero_screenshot prefers the one marked hero" do
    assert_equal project_screenshots(:krazoom_panels), projects(:krazoom).hero_screenshot
  end

  test "released and planned updates are separated" do
    project = projects(:krazoom)
    assert_equal [ project_updates(:planned_pro) ], project.planned_updates
    assert_equal 2, project.released_updates.size
  end

  test "locked fields are remembered" do
    project = projects(:krazoom)
    assert_not project.locked?(:tagline)

    project.lock!(:tagline)
    assert project.reload.locked?("tagline")
  end

  test "the timeline runs newest release first and ends with the planned entries" do
    assert_equal [ "New: panel mode", "Saved searches", "Pro features" ],
      projects(:krazoom).updates.pluck(:title)
  end

  test "github_url is nil without a repository" do
    assert_nil projects(:pagebee).github_url
    assert_equal "https://github.com/webmatze/krazoom", projects(:krazoom).github_url
  end
  test "a blank repository is stored as nil so two repo-less projects can coexist" do
    first = Project.create!(name: "One", kind: "website", status: "active", github_repo: "")
    second = Project.create!(name: "Two", kind: "website", status: "active", github_repo: "")

    assert_nil first.github_repo
    assert_nil second.github_repo
  end
end
