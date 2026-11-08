# The feed that Spotify, Apple Podcasts, Amazon Music and the rest subscribe to.
# Written by hand rather than through a gem: the tags a directory insists on are
# few, and this way it is visible which of them we promise to fill.
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0",
  "xmlns:itunes" => "http://www.itunes.com/dtds/podcast-1.0.dtd",
  "xmlns:content" => "http://purl.org/rss/1.0/modules/content/",
  "xmlns:atom" => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.title @podcast.title
    xml.link podcast_url(@podcast)
    xml.description @podcast.localized_description.to_s
    xml.language @podcast.language
    xml.copyright t("footer.copyright", year: Date.current.year)
    xml.lastBuildDate (@podcast.last_published_at || @podcast.updated_at).to_time.rfc2822
    xml.generator "mathiaskarstaedt.de"
    xml.tag! "atom:link", href: feed_podcast_url(@podcast), rel: "self", type: "application/rss+xml"

    xml.tag! "itunes:author", @podcast.author.to_s
    xml.tag! "itunes:summary", @podcast.localized_description.to_s
    xml.tag! "itunes:subtitle", @podcast.localized_tagline.to_s
    xml.tag! "itunes:type", "episodic"
    xml.tag! "itunes:explicit", @podcast.explicit? ? "true" : "false"
    xml.tag! "itunes:category", text: @podcast.category
    xml.tag! "itunes:owner" do
      xml.tag! "itunes:name", @podcast.author.to_s
      xml.tag! "itunes:email", @podcast.owner_email.to_s
    end
    if @podcast.cover.attached?
      cover = rails_storage_proxy_url(@podcast.cover.variant(:feed))
      xml.tag! "itunes:image", href: cover
      xml.image do
        xml.url cover
        xml.title @podcast.title
        xml.link podcast_url(@podcast)
      end
    end

    @episodes.each do |episode|
      xml.item do
        xml.title episode.localized_title
        xml.link podcast_episode_url(@podcast, episode)
        xml.guid episode.guid, isPermaLink: "false"
        xml.pubDate episode.published_at.to_time.rfc2822
        xml.description episode.localized_summary.to_s
        xml.tag! "content:encoded" do
          xml.cdata! episode_feed_html(episode)
        end

        if episode.audio.attached?
          xml.enclosure url: rails_storage_proxy_url(episode.audio),
            length: episode.audio.byte_size,
            type: episode.audio.content_type
        end

        xml.tag! "itunes:title", episode.localized_title
        xml.tag! "itunes:episode", episode.number if episode.number
        xml.tag! "itunes:duration", episode.duration if episode.duration
        xml.tag! "itunes:summary", episode.localized_summary.to_s
        xml.tag! "itunes:explicit", episode.explicit? ? "true" : "false"
        xml.tag! "itunes:author", @podcast.author.to_s
      end
    end
  end
end
