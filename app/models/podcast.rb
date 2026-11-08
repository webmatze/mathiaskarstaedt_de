# A show. Each one carries the metadata a podcast directory asks for — author,
# owner e-mail, language, category, cover art — because the site serves its own
# RSS feed and that feed is what Spotify, Apple and the rest subscribe to.
class Podcast < ApplicationRecord
  include Translatable

  # Apple's category list is the one every other directory follows. These are the
  # ones a show from here plausibly falls into; the feed writes the value verbatim.
  CATEGORIES = [
    "Technology", "Education", "Business", "News", "Society & Culture",
    "Arts", "Leisure", "Science"
  ].freeze

  translates :tagline, :description

  has_many :episodes, class_name: "Podcast::Episode", dependent: :destroy

  accepts_nested_attributes_for :episodes, allow_destroy: true, reject_if: :all_blank

  has_one_attached :cover do |attachable|
    # 3000×3000 is Apple's requirement and the largest anyone asks for; the small
    # variant is what the site itself shows.
    attachable.variant :feed, resize_to_fill: [ 3000, 3000 ], format: :jpeg, saver: { quality: 86 }
    attachable.variant :card, resize_to_fill: [ 640, 640 ], format: :webp, saver: { quality: 82 }
  end

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9][a-z0-9\-]*\z/, message: :invalid_slug }
  validates :language, presence: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :owner_email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :accent_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, allow_blank: true }

  before_validation :generate_slug, on: :create

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(Arel.sql("position IS NULL"), position: :asc, title: :asc) }

  def to_param
    slug
  end

  def published_episodes
    episodes.published
  end

  def latest_episode
    published_episodes.first
  end

  def last_published_at
    published_episodes.maximum(:published_at)
  end

  # Falls back to the site accent so a show without its own colour still looks
  # like the rest of the site rather than like nothing.
  def color
    accent_color.presence || SiteProfile.current.accent_color
  end

  # A feed without a cover, an author or at least one episode is rejected by the
  # directories. Saying so in the admin beats finding out from Spotify's reviewer.
  def feed_problems
    problems = []
    problems << :cover unless cover.attached?
    problems << :author if author.blank?
    problems << :owner_email if owner_email.blank?
    problems << :description if description.blank?
    problems << :episodes if published_episodes.none?
    problems << :audio if published_episodes.any? && published_episodes.none? { |episode| episode.audio.attached? }
    problems
  end

  def feed_ready?
    feed_problems.empty?
  end

  private
    def generate_slug
      self.slug = title.to_s.parameterize if slug.blank?
    end
end
