module Github
  # Pulls a project's facts and releases from GitHub.
  #
  # It only ever writes the English base columns: GitHub's descriptions and release
  # notes are English, and the German copy in `translations` is the owner's own.
  # Fields listed in the project's `locked_fields` are left alone entirely, so
  # hand-written copy survives every sync.
  class RepositorySync
    SYNCABLE_FIELDS = %w[ tagline tech_stack license homepage_url source_url ].freeze

    def initialize(project, client: Client.new)
      @project = project
      @client = client
    end

    def call
      raise Error, "Project is not connected to a GitHub repository" unless @project.github_connected?

      repository = @client.repository(@project.github_repo)
      releases = @client.releases(@project.github_repo)

      @project.transaction do
        apply_repository(repository)
        apply_releases(releases)
        @project.github_synced_at = Time.current
        @project.github_sync_error = nil
        @project.save!
      end

      @project
    rescue Error => error
      @project.update_columns(github_sync_error: error.message, github_synced_at: Time.current)
      raise
    end

    private
      def apply_repository(repository)
        assign :tagline, repository.description
        assign :tech_stack, repository.language
        assign :license, repository.license&.spdx_id
        assign :homepage_url, repository.homepage
        assign :source_url, repository.html_url

        @project.github_stars = repository.stargazers_count
        @project.status = "archived" if repository.archived? && @project.status != "archived"
        @project.last_activity_at = [ @project.last_activity_at, repository.pushed_at ].compact.max
      end

      # A field the owner has edited stays as it is. Fields that are still blank
      # are always filled, locked or not — there is nothing to protect.
      def assign(field, value)
        return if value.blank?
        return if @project.locked?(field) && @project[field].present?

        @project[field] = value
      end

      def apply_releases(releases)
        published = releases.reject(&:draft?)

        published.each { |release| apply_release(release) }

        # The newest release's first asset is the one the big download button uses.
        newest = published.max_by { |release| release.published_at || release.created_at }
        feature_primary_asset(newest) if newest
      end

      def apply_release(release)
        update = @project.updates.find_or_initialize_by(github_release_id: release.id)

        update.version ||= release.tag_name
        update.title = release.name.presence || release.tag_name if update.title.blank? || update.from_github?
        update.body = release.body.presence if update.body.blank? || update.from_github?
        update.released_on = (release.published_at || release.created_at)&.to_date
        update.state = "released"
        update.url = release.html_url
        update.save!

        release.assets.each { |asset| apply_asset(release, asset) }
      end

      def apply_asset(release, asset)
        download = @project.downloads.find_or_initialize_by(url: asset.browser_download_url)

        download.label ||= asset.name
        download.version ||= release.tag_name
        download.file_type ||= File.extname(asset.name).delete_prefix(".").presence
        download.byte_size = asset.size
        download.save!
      end

      def feature_primary_asset(release)
        primary = release.assets.first or return

        @project.downloads.reload
        @project.downloads.where(featured: true).update_all(featured: false)
        @project.downloads.find_by(url: primary.browser_download_url)&.update!(featured: true)
      end
  end
end
