# One entry in a project's update timeline. Released entries usually come from a
# GitHub release; planned entries are written by hand to show what is coming.
class Project::Update < ApplicationRecord
  include Translatable

  STATES = %w[ released planned ].freeze

  translates :title, :body

  belongs_to :project

  validates :title, presence: true
  validates :state, inclusion: { in: STATES }

  # Released entries come first, newest at the top; planned ones close the list.
  default_scope {
    order(Arel.sql("CASE state WHEN 'planned' THEN 1 ELSE 0 END"),
          Arel.sql("released_on IS NULL"), released_on: :desc, id: :desc)
  }
  scope :released, -> { where(state: "released") }
  scope :planned, -> { where(state: "planned") }
  scope :from_github, -> { where.not(github_release_id: nil) }

  def released?
    state == "released"
  end

  def planned?
    state == "planned"
  end

  def from_github?
    github_release_id.present?
  end
end
