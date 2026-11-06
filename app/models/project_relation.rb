class ProjectRelation < ApplicationRecord
  belongs_to :project
  belongs_to :related_project, class_name: "Project"

  validates :related_project_id, uniqueness: { scope: :project_id }
  validate :cannot_relate_to_itself

  default_scope { order(Arel.sql("position IS NULL"), position: :asc, id: :asc) }

  private
    def cannot_relate_to_itself
      errors.add(:related_project, :itself) if project_id.present? && project_id == related_project_id
    end
end
