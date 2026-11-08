class SitemapsController < PublicController
  def show
    @projects = Project.published.recent
    @podcasts = Podcast.published.ordered
    render formats: :xml
  end
end
