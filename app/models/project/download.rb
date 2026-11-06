class Project::Download < ApplicationRecord
  include Translatable

  translates :label

  belongs_to :project

  validates :url, presence: true

  default_scope { order(Arel.sql("position IS NULL"), position: :asc, id: :asc) }

  # "dmg · 14.2 MB · Apple Silicon" — the meta line under the download button.
  def meta_line
    [ file_type, human_size, architecture ].compact_blank.join(" · ").presence
  end

  def human_size
    ActiveSupport::NumberHelper.number_to_human_size(byte_size) if byte_size.to_i.positive?
  end
end
