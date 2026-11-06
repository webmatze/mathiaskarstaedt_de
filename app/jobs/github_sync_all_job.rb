# The nightly run (see config/recurring.yml). One job per project so a single
# failing repository does not stop the rest.
class GithubSyncAllJob < ApplicationJob
  queue_as :default

  def perform
    return Rails.logger.info("GitHub sync skipped: no token configured") unless Github::Client.configured?

    Project.connected_to_github.each { |project| GithubSyncJob.perform_later(project) }
  end
end
