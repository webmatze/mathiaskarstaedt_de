class PagesController < PublicController
  def home
    @featured_projects = Project.published.featured.includes(:screenshots, screenshots: { image_attachment: :blob })
    @projects = Project.published.recent.includes(screenshots: { image_attachment: :blob })
    @kinds = ProjectKind.all
  end

  def imprint
  end

  def privacy
  end
end
