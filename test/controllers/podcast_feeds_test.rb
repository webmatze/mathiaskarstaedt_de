require "test_helper"

# The feed is the part a podcast directory reads, so the tags it insists on are
# asserted here rather than left to a page test.
class PodcastFeedsTest < ActionDispatch::IntegrationTest
  setup do
    @podcast = podcasts(:rails_am_abend)
    @episode = podcast_episodes(:first)
    @episode.audio.attach(
      io: file_fixture("episode.mp3").open, filename: "episode-01.mp3", content_type: "audio/mpeg"
    )
  end

  test "the feed carries the channel metadata a directory requires" do
    get feed_podcast_path(@podcast, format: :rss)

    assert_response :success
    assert_equal "application/rss+xml", response.media_type

    feed = Nokogiri::XML(response.body)
    assert_equal "Rails am Abend", feed.at_xpath("//channel/title").text
    assert_equal "de", feed.at_xpath("//channel/language").text
    assert_equal "Mathias Karstädt", feed.at_xpath("//channel/itunes:author", itunes_ns).text
    assert_equal "podcast@mathiaskarstaedt.de", feed.at_xpath("//channel/itunes:owner/itunes:email", itunes_ns).text
    assert_equal "Technology", feed.at_xpath("//channel/itunes:category", itunes_ns)["text"]
    assert_equal feed_podcast_url(@podcast, format: :rss), feed.at_xpath("//channel/atom:link", atom_ns)["href"]
  end

  test "the feed lists the published episodes with a playable enclosure" do
    get feed_podcast_path(@podcast, format: :rss)

    feed = Nokogiri::XML(response.body)
    items = feed.xpath("//channel/item")

    assert_equal 2, items.size, "the unpublished episode stays out of the feed"
    assert_equal "Hotwire all the way", items.first.at_xpath("title").text, "newest first"

    # The show's language is German, so the feed carries the German titles.
    item = items.find { |candidate| candidate.at_xpath("title").text == "Warum Rails im Jahr 2026" }
    enclosure = item.at_xpath("enclosure")
    assert_equal "audio/mpeg", enclosure["type"]
    assert_equal @episode.audio.byte_size.to_s, enclosure["length"]
    assert_match "episode-01.mp3", enclosure["url"]
    assert_no_match(/locale=/, enclosure["url"], "a directory stores this URL — it must not carry a locale")
    assert_equal "1:01:11", item.at_xpath("itunes:duration", itunes_ns).text
    assert_equal "1", item.at_xpath("itunes:episode", itunes_ns).text
    assert_equal @episode.guid, item.at_xpath("guid").text
  end

  test "the feed is written in the show's own language, not the visitor's" do
    get feed_podcast_path(@podcast, format: :rss, locale: :de)
    german = Nokogiri::XML(response.body).at_xpath("//channel/item/title").text

    get feed_podcast_path(@podcast, format: :rss)

    assert_equal german, Nokogiri::XML(response.body).at_xpath("//channel/item/title").text,
      "a German show reads the same whoever asks for the feed"
  end

  test "an unpublished show has no feed" do
    get feed_podcast_path(podcasts(:draft_show), format: :rss)

    assert_response :not_found
  end

  private
    def itunes_ns
      { "itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd" }
    end

    def atom_ns
      { "atom" => "http://www.w3.org/2005/Atom" }
    end
end
