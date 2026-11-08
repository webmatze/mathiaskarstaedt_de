class Admin::PodcastsController < Admin::BaseController
  before_action :set_podcast, only: %i[ show edit update destroy ]

  def index
    @podcasts = Podcast.ordered
  end

  def show
    redirect_to edit_admin_podcast_path(@podcast)
  end

  def new
    @podcast = Podcast.new(author: t("site.owner"), language: I18n.locale.to_s)
  end

  def create
    @podcast = Podcast.new(podcast_params)

    if @podcast.save
      redirect_to edit_admin_podcast_path(@podcast), notice: t("admin.flash.podcast_created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @podcast.update(podcast_params)
      redirect_to edit_admin_podcast_path(@podcast), notice: t("admin.flash.podcast_updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @podcast.destroy!
    redirect_to admin_podcasts_path, notice: t("admin.flash.podcast_destroyed")
  end

  private
    def set_podcast
      @podcast = Podcast.find_by!(slug: params[:id])
    end

    def podcast_params
      params.expect(podcast: [
        :title, :slug, :tagline, :description, :author, :owner_email, :language,
        :category, :explicit, :published, :position, :youtube_url, :spotify_url,
        :apple_url, :accent_color, :cover,
        { translations: [ { de: Podcast.translatable_fields.map(&:to_sym) } ] }
      ])
    end
end
