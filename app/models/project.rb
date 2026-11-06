class Project < ApplicationRecord
  include Translatable

  STATUSES = %w[ active maintained archived planned ].freeze

  translates :tagline, :description

  has_many :features, class_name: "Project::Feature", dependent: :destroy
  has_many :screenshots, class_name: "Project::Screenshot", dependent: :destroy
  has_many :updates, class_name: "Project::Update", dependent: :destroy
  has_many :downloads, class_name: "Project::Download", dependent: :destroy
  has_many :links, class_name: "Project::Link", dependent: :destroy

  has_many :relations, class_name: "ProjectRelation", dependent: :destroy
  has_many :related_projects, through: :relations, source: :related_project
  has_many :inverse_relations, class_name: "ProjectRelation",
    foreign_key: :related_project_id, dependent: :destroy

  accepts_nested_attributes_for :features, :screenshots, :updates, :downloads, :links,
    allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :relations, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9][a-z0-9\-]*\z/, message: :invalid_slug }
  validates :kind, inclusion: { in: ProjectKind::ALL }
  validates :status, inclusion: { in: STATUSES }
  validates :github_repo, format: { with: %r{\A[\w.\-]+/[\w.\-]+\z}, allow_blank: true }

  # The admin's checkbox group always posts a blank entry so unchecking the last
  # box still sends the key.
  normalizes :locked_fields, with: ->(fields) { Array(fields).compact_blank.map(&:to_s).uniq }

  before_validation :generate_slug, on: :create
  before_save :default_last_activity_at

  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true).order(Arel.sql("featured_position IS NULL"), featured_position: :asc) }
  scope :recent, -> { order(Arel.sql("last_activity_at IS NULL"), last_activity_at: :desc, name: :asc) }
  scope :of_kind, ->(kind) { where(kind: kind) if ProjectKind::ALL.include?(kind.to_s) }
  scope :connected_to_github, -> { where.not(github_repo: [ nil, "" ]) }

  def to_param
    slug
  end

  def project_kind
    ProjectKind.find(kind)
  end

  def status_label
    I18n.t("project_statuses.#{status}")
  end

  def hero_screenshot
    screenshots.detect { |screenshot| screenshot.hero? } || screenshots.first
  end

  def featured_download
    downloads.detect { |download| download.featured? } || downloads.first
  end

  def released_updates
    updates.select { |update| update.released? }
  end

  def planned_updates
    updates.select { |update| update.planned? }
  end

  # A field the owner has written by hand must survive the next GitHub sync.
  def locked?(field)
    locked_fields.include?(field.to_s)
  end

  def lock!(field)
    update!(locked_fields: locked_fields | [ field.to_s ])
  end

  def github_connected?
    github_repo.present?
  end

  def github_url
    "https://github.com/#{github_repo}" if github_connected?
  end

  private
    def generate_slug
      self.slug = name.to_s.parameterize if slug.blank?
    end

    def default_last_activity_at
      self.last_activity_at ||= Time.current
    end
end
