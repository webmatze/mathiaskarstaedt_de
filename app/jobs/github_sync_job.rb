# Refreshes one project from GitHub. Failures are recorded on the project and
# shown in the admin rather than retried forever.
class GithubSyncJob < ApplicationJob
  queue_as :default

  def perform(project)
    Github::RepositorySync.new(project).call
  rescue Github::Error => error
    Rails.logger.warn "GitHub sync failed for #{project.github_repo}: #{error.message}"
  end
end
