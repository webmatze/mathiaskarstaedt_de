module PodcastsHelper
  # The shownotes as they go into the feed: the rendered Markdown plus a link back
  # to the episode page, because a podcast app is where most people will read them.
  def episode_feed_html(episode)
    [
      markdown(episode.localized_show_notes).to_s.presence,
      tag.p(link_to(t("podcasts.feed.episode_page"), podcast_episode_url(episode.podcast, episode)))
    ].compact.join("\n")
  end

  # One row of "listen here" buttons. Takes whichever of the links a show has, and
  # always offers the feed itself for an app that is not on the list.
  def podcast_subscribe_links(podcast)
    [
      ([ t("podcasts.subscribe.spotify"), podcast.spotify_url ] if podcast.spotify_url.present?),
      ([ t("podcasts.subscribe.apple"), podcast.apple_url ] if podcast.apple_url.present?),
      ([ t("podcasts.subscribe.youtube"), podcast.youtube_url ] if podcast.youtube_url.present?)
    ].compact
  end

  def episode_number_label(episode)
    t("podcasts.episode.number", number: episode.number) if episode.number
  end
end
