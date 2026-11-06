class SitemapsController < PublicController
  def show
    @projects = Project.published.recent
    render formats: :xml
  end
end
