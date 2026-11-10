class ProjectsController < PublicController
  def index
    @kind = ProjectKind.find(params[:kind])
    @projects = Project.published.of_kind(@kind&.key).recent.includes(screenshots: { image_attachment: :blob })
    @kinds = ProjectKind.all
  end

  def show
    @project = Project.published.includes(
      :features, :updates, :downloads, :links,
      screenshots: { image_attachment: :blob },
      related_projects: { screenshots: { image_attachment: :blob } }
    ).find_by!(slug: params[:slug])
  end
end
