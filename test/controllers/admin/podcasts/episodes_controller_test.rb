require "test_helper"

class Admin::Podcasts::EpisodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    @podcast = podcasts(:rails_am_abend)
  end

  test "the new form suggests the next episode number" do
    get new_admin_podcast_episode_path(@podcast)

    assert_response :success
    assert_select "input[name=?][value=?]", "episode[number]", "4"
  end

  test "creates an episode with an audio file" do
    assert_difference -> { @podcast.episodes.count }, 1 do
      post admin_podcast_episodes_path(@podcast), params: { episode: {
        title: "Kamal in Praxis", number: 4, summary: "Deploying without Kubernetes.",
        audio: fixture_file_upload("episode.mp3", "audio/mpeg"),
        published: "1"
      } }
    end

    episode = @podcast.episodes.find_by!(slug: "kamal-in-praxis")
    assert_redirected_to edit_admin_podcast_episode_path(@podcast, episode)
    assert episode.audio.attached?
  end

  test "the edit form renders and keeps the German fields" do
    get edit_admin_podcast_episode_path(@podcast, podcast_episodes(:first))

    assert_response :success
    assert_select "textarea[name=?]", "episode[translations][de][show_notes]"
  end

  test "an invalid episode comes back with its errors" do
    post admin_podcast_episodes_path(@podcast), params: { episode: { title: "" } }

    assert_response :unprocessable_content
  end

  test "deletes an episode" do
    assert_difference -> { @podcast.episodes.count }, -1 do
      delete admin_podcast_episode_path(@podcast, podcast_episodes(:second))
    end

    assert_redirected_to edit_admin_podcast_path(@podcast)
  end
end
