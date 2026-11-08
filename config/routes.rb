Rails.application.routes.draw do
  # Public site. Paths are English; the German locale is prepared in the
  # locale files and switched on by wrapping these routes in:
  #
  #   scope "(:locale)", locale: /de/ do … end
  #
  # ApplicationController#set_locale already honours params[:locale], so turning
  # the second language on is a routing change and nothing else.
  root "pages#home"
  resources :projects, only: %i[ index show ], param: :slug

  # Each show serves its own RSS feed — that URL is what gets submitted to
  # Spotify, Apple Podcasts and the rest, so it must never change.
  resources :podcasts, only: %i[ index show ], param: :slug do
    get "feed", on: :member, defaults: { format: :rss }, as: :feed
    resources :episodes, only: :show, param: :slug, module: :podcasts
  end

  get "imprint" => "pages#imprint", as: :imprint
  get "privacy" => "pages#privacy", as: :privacy
  get "sitemap" => "sitemaps#show", as: :sitemap, defaults: { format: :xml }

  # Admin
  resource :session
  resources :passwords, param: :token

  namespace :admin do
    root "projects#index"
    resources :projects do
      resource :github_sync, only: :create, module: :projects
    end
    resources :podcasts do
      resources :episodes, except: :show, module: :podcasts
    end
    resource :site_profile, only: %i[ edit update ]
    resources :github_imports, only: %i[ new create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
