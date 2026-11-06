class ProjectsController < PublicController
  def index
    @kind = ProjectKind.find(params[:kind])
    @projects = Project.published.of_kind(@kind&.key).recent
    @kinds = ProjectKind.all
  end

  def show
    @project = Project.published.includes(
      :features, :updates, :downloads, :links,
      screenshots: { image_attachment: :blob },
      related_projects: :screenshots
    ).find_by!(slug: params[:slug])
  end
end
