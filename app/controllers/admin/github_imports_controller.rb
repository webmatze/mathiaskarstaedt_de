# Type owner/repo, get a project draft filled in from GitHub, then edit the copy.
class Admin::GithubImportsController < Admin::BaseController
  def new
  end

  def create
    repo = params[:repo].to_s.strip
    project = Github::RepositoryImport.new(repo).call

    redirect_to edit_admin_project_path(project), notice: t("admin.github_imports.created", repo: repo)
  rescue Github::Error, ActiveRecord::RecordInvalid => error
    flash.now[:alert] = t("admin.github_imports.failed", repo: repo, error: error.message)
    render :new, status: :unprocessable_content
  end
end
