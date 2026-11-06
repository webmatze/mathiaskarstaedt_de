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

      if project.new_record?
        name = @repo.split("/").last
        project.assign_attributes(name: name.humanize.titleize, slug: name.parameterize,
          kind: "library", status: "active", published: false)
        project.save!
      end

      RepositorySync.new(project, client: @client).call
    end
  end
end
