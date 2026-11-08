class PodcastsController < PublicController
  before_action :set_podcast, only: %i[ show feed ]

  def index
    @podcasts = Podcast.published.ordered.with_attached_cover
  end

  def show
    @episodes = @podcast.published_episodes.includes(audio_attachment: :blob)
  end

  # The RSS feed every podcast directory subscribes to. Rendered for the show's own
  # language rather than the visitor's, because a feed is not a page: the <language>
  # tag and the copy inside it have to agree.
  def feed
    I18n.with_locale(feed_locale) do
      @episodes = @podcast.published_episodes.includes(audio_attachment: :blob)
      render formats: :rss, layout: false
    end
  end

  private
    def set_podcast
      @podcast = Podcast.published.find_by!(slug: params[:slug] || params[:id])
    end

    # The feed renders under the show's locale, but its URLs are the canonical ones
    # a directory stores and comes back to — no ?locale= on them.
    def default_url_options
      action_name == "feed" ? {} : super
    end

    def feed_locale
      @podcast.language.to_s.split("-").first.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    end
end
