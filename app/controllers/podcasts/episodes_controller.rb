class Podcasts::EpisodesController < PublicController
  def show
    @podcast = Podcast.published.find_by!(slug: params[:podcast_slug])
    @episode = @podcast.published_episodes.find_by!(slug: params[:slug])
    @other_episodes = @podcast.published_episodes.where.not(id: @episode.id).limit(3)
  end
end
