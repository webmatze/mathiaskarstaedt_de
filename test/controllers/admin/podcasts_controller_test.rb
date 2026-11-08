require "test_helper"

class Admin::PodcastsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "the admin is closed without a session" do
    reset!

    get admin_podcasts_path
    assert_redirected_to new_session_path
  end

  test "the index lists drafts alongside published shows and flags the feed" do
    get admin_podcasts_path

    assert_response :success
    assert_match "Rails am Abend", response.body
    assert_match "Draft Show", response.body
    assert_match "incomplete", response.body, "neither show has cover art yet"
  end

  test "the new and edit forms render" do
    get new_admin_podcast_path
    assert_response :success

    get edit_admin_podcast_path(podcasts(:rails_am_abend))
    assert_response :success
    assert_select "textarea[name=?]", "podcast[translations][de][tagline]"
    assert_match feed_podcast_url(podcasts(:rails_am_abend), format: :rss), response.body
  end

  test "creates a podcast with its German copy" do
    assert_difference -> { Podcast.count }, 1 do
      post admin_podcasts_path, params: { podcast: {
        title: "Hamburg Hackt", category: "Technology", language: "de",
        tagline: "A monthly meetup, recorded.",
        translations: { de: { tagline: "Ein monatliches Treffen, aufgenommen." } }
      } }
    end

    podcast = Podcast.find_by!(slug: "hamburg-hackt")
    assert_redirected_to edit_admin_podcast_path(podcast)
    assert_equal "Ein monatliches Treffen, aufgenommen.", podcast.localized(:tagline, locale: :de)
  end

  test "an invalid podcast comes back with its errors" do
    post admin_podcasts_path, params: { podcast: { title: "", category: "Technology" } }

    assert_response :unprocessable_content
  end

  test "deletes a podcast and its episodes" do
    assert_difference -> { Podcast::Episode.count }, -3 do
      delete admin_podcast_path(podcasts(:rails_am_abend))
    end

    assert_redirected_to admin_podcasts_path
  end
end
