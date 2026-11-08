class Admin::Podcasts::EpisodesController < Admin::BaseController
  before_action :set_podcast
  before_action :set_episode, only: %i[ edit update destroy ]

  def index
    redirect_to edit_admin_podcast_path(@podcast)
  end

  def new
    @episode = @podcast.episodes.new(number: next_number, published_at: Time.current)
  end

  def create
    @episode = @podcast.episodes.new(episode_params)

    if @episode.save
      redirect_to edit_admin_podcast_episode_path(@podcast, @episode), notice: t("admin.flash.episode_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @episode.update(episode_params)
      redirect_to edit_admin_podcast_episode_path(@podcast, @episode), notice: t("admin.flash.episode_updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @episode.destroy!
    redirect_to edit_admin_podcast_path(@podcast), notice: t("admin.flash.episode_destroyed")
  end

  private
    def set_podcast
      @podcast = Podcast.find_by!(slug: params[:podcast_id])
    end

    def set_episode
      @episode = @podcast.episodes.find_by!(slug: params[:id])
    end

    def next_number
      (@podcast.episodes.maximum(:number) || 0) + 1
    end

    def episode_params
      params.expect(episode: [
        :title, :slug, :number, :summary, :show_notes, :transcript, :youtube_url,
        :published_at, :duration_seconds, :explicit, :published, :audio,
        { translations: [ { de: Podcast::Episode.translatable_fields.map(&:to_sym) } ] }
      ])
    end
end
