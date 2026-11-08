require "test_helper"

class PodcastsControllerTest < ActionDispatch::IntegrationTest
  test "the index lists the published shows only" do
    get podcasts_path

    assert_response :success
    assert_select "a[href=?]", podcast_path(podcasts(:rails_am_abend))
    assert_select "a[href=?]", podcast_path(podcasts(:draft_show)), count: 0
  end

  test "the show page lists the published episodes and the feed URL" do
    get podcast_path(podcasts(:rails_am_abend))

    assert_response :success
    assert_select "h1", text: "Rails am Abend"
    assert_select "a[href=?]", podcast_episode_path(podcasts(:rails_am_abend), podcast_episodes(:first))
    assert_select "a[href=?]", podcast_episode_path(podcasts(:rails_am_abend), podcast_episodes(:unpublished)), count: 0
    assert_match feed_podcast_url(podcasts(:rails_am_abend), format: :rss), response.body
  end

  test "an unpublished show is not reachable" do
    get podcast_path(podcasts(:draft_show))

    assert_response :not_found
  end

  test "the episode page embeds the video and shows the shownotes" do
    get podcast_episode_path(podcasts(:rails_am_abend), podcast_episodes(:first))

    assert_response :success
    assert_select "h1", text: "Why Rails in 2026"
    assert_select "iframe[src=?]", "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ"
    assert_select "h2", text: "Shownotes"
    assert_match "Links and timestamps", response.body
    assert_match "1:01:11", response.body, "the duration is shown"
  end

  test "an unpublished episode is not reachable" do
    get podcast_episode_path(podcasts(:rails_am_abend), podcast_episodes(:unpublished))

    assert_response :not_found
  end

  test "the episode page renders in German" do
    get podcast_episode_path(podcasts(:rails_am_abend), podcast_episodes(:first), locale: :de)

    assert_response :success
    assert_select "h1", text: "Warum Rails im Jahr 2026"
    assert_match "Folge 1", response.body
    assert_no_match(/translation missing/, response.body)
  end
end
