class Project::Link < ApplicationRecord
  include Translatable

  translates :label

  belongs_to :project

  validates :label, :url, presence: true

  before_save :default_display_url

  default_scope { order(Arel.sql("position IS NULL"), position: :asc, id: :asc) }

  private
    # The design shows the bare host next to the label, e.g. "krazoom.app ↗".
    def default_display_url
      return if display_url.present?

      self.display_url = URI.parse(url).host&.delete_prefix("www.")
    rescue URI::InvalidURIError
      nil
    end
end
