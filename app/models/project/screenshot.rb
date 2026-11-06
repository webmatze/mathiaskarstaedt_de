class Project::Screenshot < ApplicationRecord
  include Translatable

  translates :caption

  belongs_to :project
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 480, 300 ], format: :webp, saver: { quality: 80 }
    attachable.variant :large, resize_to_limit: [ 1840, 1400 ], format: :webp, saver: { quality: 82 }
  end

  validates :image, presence: true, unless: :video_url?

  default_scope { order(Arel.sql("position IS NULL"), position: :asc, id: :asc) }
  scope :heroes, -> { where(hero: true) }

  def video?
    video_url.present?
  end

  def video_url?
    video_url.present?
  end
end
