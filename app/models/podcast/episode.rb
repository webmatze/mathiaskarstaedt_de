# One episode. The audio file is what the RSS feed hands to Spotify and Apple;
# `youtube_url` is the same episode as video, embedded on the episode page.
class Podcast::Episode < ApplicationRecord
  include Translatable

  translates :title, :summary, :show_notes

  belongs_to :podcast

  has_one_attached :audio

  validates :title, presence: true
  validates :slug, presence: true,
    format: { with: /\A[a-z0-9][a-z0-9\-]*\z/, message: :invalid_slug },
    uniqueness: { scope: :podcast_id }
  validates :number, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validates :duration_seconds, numericality: { only_integer: true, greater_than: 0, allow_nil: true }
  validate :audio_must_be_audio

  before_validation :generate_slug, on: :create
  before_save :default_published_at

  # Newest first, which is both what the page shows and the order a feed is
  # conventionally written in.
  default_scope { order(Arel.sql("published_at IS NULL"), published_at: :desc, number: :desc, id: :desc) }
  scope :published, -> { where(published: true).where.not(published_at: nil).where(published_at: ..Time.current) }

  def to_param
    slug
  end

  # The feed's <guid>. It must never change for an episode once it is out, so it
  # is built from ids rather than from the slug, which the admin can still edit.
  def guid
    "podcast-#{podcast_id}-episode-#{id}"
  end

  def duration
    return nil if duration_seconds.blank?

    format("%d:%02d:%02d", duration_seconds / 3600, (duration_seconds % 3600) / 60, duration_seconds % 60)
  end

  # "42:13" for the badge on the page — the feed wants the padded form above.
  def short_duration
    return nil if duration_seconds.blank?

    duration_seconds >= 3600 ? duration : format("%d:%02d", duration_seconds / 60, duration_seconds % 60)
  end

  def youtube_id
    return nil if youtube_url.blank?

    uri = URI.parse(youtube_url) rescue nil
    return nil if uri.nil?

    case uri.host
    when "youtu.be" then uri.path.delete_prefix("/").presence
    when /(\A|\.)youtube\.com\z/
      Rack::Utils.parse_nested_query(uri.query.to_s)["v"].presence ||
        uri.path[%r{\A/(?:embed|shorts|live)/([^/]+)}, 1]
    end
  end

  def youtube_embed_url
    "https://www.youtube-nocookie.com/embed/#{youtube_id}" if youtube_id
  end

  # An enclosure a directory can play. The content type is the blob's own, so a
  # mislabelled upload is caught here rather than by Spotify's ingest.
  AUDIO_TYPES = %w[ audio/mpeg audio/mp4 audio/aac audio/x-m4a ].freeze

  private
    def audio_must_be_audio
      return unless audio.attached?
      return if audio.blob.content_type.in?(AUDIO_TYPES)

      errors.add(:audio, :invalid_audio)
    end

    def generate_slug
      self.slug = title.to_s.parameterize if slug.blank?
    end

    def default_published_at
      self.published_at ||= Time.current if published?
    end
end
