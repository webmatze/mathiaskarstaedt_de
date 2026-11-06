class Project::Feature < ApplicationRecord
  include Translatable

  translates :title, :body

  belongs_to :project

  validates :title, presence: true

  default_scope { order(Arel.sql("position IS NULL"), position: :asc, id: :asc) }
end
