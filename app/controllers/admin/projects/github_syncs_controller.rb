# "Sync now" on a project: queue the same job the nightly run uses, so there is
# only one code path that talks to GitHub.
class Admin::Projects::GithubSyncsController < Admin::BaseController
  def create
    project = Project.find_by!(slug: params[:project_id])
    GithubSyncJob.perform_later(project)

    redirect_back fallback_location: edit_admin_project_path(project),
      notice: t("admin.projects.sync.queued")
  end
end
