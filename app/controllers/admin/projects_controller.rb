class Admin::ProjectsController < Admin::BaseController
  before_action :set_project, only: %i[ edit update destroy ]

  def index
    @projects = Project.recent
  end

  def new
    @project = Project.new(kind: "webapp", status: "active")
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      redirect_to edit_admin_project_path(@project), notice: t("admin.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to edit_admin_project_path(@project), notice: t("admin.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @project.destroy!
    redirect_to admin_projects_path, notice: t("admin.flash.destroyed")
  end

  private
    # Project#to_param is the slug, so the admin routes carry it too.
    def set_project
      @project = Project.find_by!(slug: params[:id])
    end

    def project_params
      params.expect(project: [
        :name, :slug, :tagline, :description, :kind, :status,
        :platforms, :tech_stack, :price, :license, :formats,
        :published, :featured, :featured_position, :position,
        :last_activity_at, :homepage_url, :source_url, :github_repo,
        { locked_fields: [],
          translations: [ { de: Project.translatable_fields.map(&:to_sym) } ],
          features_attributes: [ nested_fields(Project::Feature, :title, :body, :position) ],
          screenshots_attributes: [ nested_fields(Project::Screenshot, :image, :caption, :video_url, :hero, :position) ],
          updates_attributes: [ nested_fields(Project::Update, :version, :title, :body, :released_on, :state, :url) ],
          downloads_attributes: [ nested_fields(Project::Download, :label, :url, :version, :file_type, :architecture, :byte_size, :featured, :position) ],
          links_attributes: [ nested_fields(Project::Link, :label, :url, :display_url, :position) ],
          relations_attributes: [ [ :id, :_destroy, :related_project_id, :position ] ] }
      ])
    end

    # An array inside an array tells `expect` to accept a collection of records,
    # which is the shape accepts_nested_attributes_for posts.
    def nested_fields(model, *fields)
      [ :id, :_destroy, *fields, { translations: [ { de: model.translatable_fields.map(&:to_sym) } ] } ]
    end
end
