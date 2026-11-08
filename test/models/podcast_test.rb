require "test_helper"

class PodcastTest < ActiveSupport::TestCase
  test "the slug comes from the title when none is given" do
    podcast = Podcast.create!(title: "Rails am Morgen")

    assert_equal "rails-am-morgen", podcast.slug
  end

  test "feed_problems names what a directory would reject" do
    podcast = podcasts(:draft_show)

    assert_includes podcast.feed_problems, :cover
    assert_includes podcast.feed_problems, :author
    assert_includes podcast.feed_problems, :owner_email
    assert_includes podcast.feed_problems, :episodes
    assert_not podcast.feed_ready?
  end

  test "a show with copy, episodes and audio is still short of a cover" do
    podcast = podcasts(:rails_am_abend)

    assert_equal %i[ cover audio ], podcast.feed_problems
  end

  test "published_episodes leaves out drafts and the future" do
    podcast = podcasts(:rails_am_abend)
    podcast.episodes.create!(title: "Next week", published: true, published_at: 1.week.from_now)

    assert_equal [ "hotwire", "warum-rails" ], podcast.published_episodes.map(&:slug)
  end

  test "the colour falls back to the site accent" do
    assert_equal SiteProfile.current.accent_color, podcasts(:rails_am_abend).color

    podcasts(:rails_am_abend).update!(accent_color: "#FF8FB1")
    assert_equal "#FF8FB1", podcasts(:rails_am_abend).color
  end
end
