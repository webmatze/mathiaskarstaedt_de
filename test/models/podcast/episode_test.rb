require "test_helper"

class Podcast::EpisodeTest < ActiveSupport::TestCase
  test "the duration is padded for the feed and short for the page" do
    episode = podcast_episodes(:first)

    assert_equal "1:01:11", episode.duration
    assert_equal "1:01:11", episode.short_duration
    assert_equal "40:00", podcast_episodes(:second).short_duration
  end

  test "the YouTube id is read from every URL shape" do
    episode = Podcast::Episode.new

    {
      "https://www.youtube.com/watch?v=abc123XYZ_-" => "abc123XYZ_-",
      "https://youtu.be/abc123XYZ_-" => "abc123XYZ_-",
      "https://www.youtube.com/embed/abc123XYZ_-" => "abc123XYZ_-",
      "https://www.youtube.com/live/abc123XYZ_-" => "abc123XYZ_-",
      "https://vimeo.com/12345" => nil,
      "" => nil
    }.each do |url, expected|
      episode.youtube_url = url
      message = url.presence || "a blank URL"
      expected.nil? ? assert_nil(episode.youtube_id, message) : assert_equal(expected, episode.youtube_id, message)
    end
  end

  test "the embed URL uses the no-cookie host" do
    assert_equal "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ", podcast_episodes(:first).youtube_embed_url
  end

  test "the guid survives a renamed slug" do
    episode = podcast_episodes(:first)
    guid = episode.guid

    episode.update!(slug: "warum-rails-doch")

    assert_equal guid, episode.reload.guid
  end

  test "a non-audio upload is rejected" do
    episode = podcast_episodes(:first)
    episode.audio.attach(io: StringIO.new("not audio"), filename: "notes.txt", content_type: "text/plain")

    assert_not episode.valid?
    assert_includes episode.errors[:audio].first, "MP3"
  end

  test "publishing without a date stamps it" do
    episode = podcasts(:rails_am_abend).episodes.create!(title: "Live", published: true)

    assert_not_nil episode.published_at
  end

  test "two shows may use the same episode slug" do
    other = podcasts(:draft_show).episodes.new(title: "Why Rails in 2026", slug: "warum-rails")

    assert other.valid?
  end
end
