module Github
  # Thin wrapper over Octokit. The token is a personal access token with the
  # `repo` scope so private repositories work too; it lives in the Rails
  # credentials, never in the environment.
  class Client
    def self.configured?
      token.present?
    end

    def self.token
      Rails.application.credentials.dig(:github, :token)
    end

    def initialize(token: self.class.token)
      raise Error, "No GitHub token configured (credentials: github.token)" if token.blank?

      @octokit = Octokit::Client.new(access_token: token, auto_paginate: false)
    end

    def repository(repo)
      wrap { @octokit.repository(repo) }
    end

    def releases(repo, per_page: 20)
      wrap { @octokit.releases(repo, per_page: per_page) }
    end

    private
      def wrap
        yield
      rescue Octokit::NotFound
        raise Error, "Repository not found or not visible with this token"
      rescue Octokit::TooManyRequests
        raise Error, "GitHub rate limit reached — try again later"
      rescue Octokit::Error => error
        raise Error, error.message
      end
  end
end
