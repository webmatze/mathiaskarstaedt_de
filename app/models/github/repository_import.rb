module Github
  # Creates a project draft from a repository, then hands over to RepositorySync
  # so import and nightly refresh share one code path.
  class RepositoryImport
    def initialize(repo, client: Client.new)
      @repo = repo
      @client = client
    end

    def call
      raise Error, "Enter the repository as owner/name" unless @repo.match?(%r{\A[\w.\-]+/[\w.\-]+\z})

      project = Project.find_or_initialize_by(github_repo: @repo)
      return sync(project) if project.persisted?

      # A new draft only stays if GitHub answers, so a mistyped repository
      # leaves nothing behind to collide with the next attempt.
      Project.transaction(requires_new: true) do
        project.assign_attributes(name: @repo.split("/").last.humanize.titleize,
          kind: "library", status: "active", published: false)
        project.save!
        sync(project)
      end
    end

    private
      def sync(project)
        RepositorySync.new(project, client: @client).call
      end
  end
end
