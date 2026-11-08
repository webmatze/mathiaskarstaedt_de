# mathiaskarstaedt.de

The portfolio behind [mathiaskarstaedt.de](https://mathiaskarstaedt.de): one place for the
web apps, Mac apps, CLI tools, games and libraries that are otherwise scattered across
GitHub, itch.io and their own landing pages.

- **Home** — hero, favourites, every published project ordered by last activity, filterable
  by type. The type (website, web app, desktop, mobile, CLI, game, library) is readable at a
  glance from a coloured badge, and the colours come from one place: `app/models/project_kind.rb`.
- **Project pages** — screenshots, description, features, an update timeline, downloads,
  a fact sheet, links and related projects.
- **Podcasts** — one page per show with its episodes, each episode page with the YouTube
  video embedded, an audio player, shownotes and a transcript. Every show serves its own
  RSS feed, which is what the podcast directories subscribe to.
- **Admin** — create and edit everything, including the German copy.
- **GitHub** — import a repository, then keep its facts, releases and release assets fresh
  with a nightly sync.

Rails 8 · SQLite · Solid Queue/Cache/Cable · Hotwire · Tailwind CSS v4 · Kamal.

## Languages

English is the language the site ships in. German is fully prepared and switched on by
wrapping the public routes in `config/routes.rb`:

```ruby
scope "(:locale)", locale: /de/ do
  root "pages#home"
  resources :projects, only: %i[ index show ], param: :slug
  # …
end
```

`ApplicationController#switch_locale` already honours `params[:locale]`, so nothing else
has to change. Two kinds of text, two mechanisms:

- **Interface text** lives in `config/locales/**/{en,de}.yml`. A test asserts both languages
  define exactly the same keys, so a forgotten translation fails CI rather than showing up as
  "translation missing" on the page.
- **Content** (taglines, descriptions, feature and update copy, the hero and about text)
  keeps English in its ordinary column and German in the record's `translations` JSON column.
  `app/models/concerns/translatable.rb` adds the `localized_*` readers that views use; a
  missing German value falls back to English. No translation gem involved.

The admin shows a German field next to each English one and a `3/7` completeness marker per
project in the index.

## Development

Ruby comes from `mise.toml` (3.4.7).

```bash
bin/setup          # bundle, prepare the database, seed
bin/dev            # Rails + Tailwind watcher on :3000
bin/rails test     # unit, model and controller tests
bin/rails test:system
bin/rubocop
```

`db/seeds.rb` fills the site with the projects from the design draft — English in the
columns, the German copy alongside — so both languages are real from the first boot.

Create the single admin user:

```bash
ADMIN_EMAIL=you@example.com ADMIN_PASSWORD=… bin/rails db:seed
```

## Podcasts

A show lives at `/podcasts/:slug`, its episodes at `/podcasts/:slug/episodes/:slug`, and its
feed at `/podcasts/:slug/feed` — that last URL is the one submitted to the directories, so it
must never change. The site is the host: the MP3 is uploaded in **Admin → Podcasts → Episode**
and goes into Active Storage, and the feed hands it out through a proxy URL (not a redirect
URL, which expires).

Per show the feed needs an author, an owner e-mail, a language, a category, square cover art
of at least 1400×1400 px and one published episode with audio. The admin lists what is still
missing and marks the show `ready` only once a directory would accept it.

Then, once per directory:

1. **Spotify** — [Spotify for Creators](https://creators.spotify.com), "I already have a
   podcast", paste the feed URL.
2. **Apple Podcasts** — [Apple Podcasts Connect](https://podcastsconnect.apple.com), same URL.
   Worth doing even if nobody there listens: several other apps read Apple's index.
3. **Amazon Music, Deezer, podcast.de, Podcast Index** — all take the same feed URL.

Afterwards paste the resulting show links into the **Directories** section; they become the
buttons on the show page. Everything else happens through the feed: a new episode appears in
every app on its own.

The video stays on YouTube. Spotify's own video playback needs the file uploaded through
Spotify for Creators and does not come from RSS, so the feed carries the audio and the
episode page embeds the video.

An episode's `<guid>` is built from the record ids rather than the slug, so renaming a slug
does not make the apps re-download the episode as new.

## GitHub sync

Add a personal access token with the `repo` scope (so private repositories work too):

```bash
bin/rails credentials:edit
```

```yml
github:
  token: ghp_…
```

Then `Admin → Import from GitHub`, enter `owner/name`, and the project is created from the
repository. `GithubSyncAllJob` refreshes every connected project nightly at 04:15
(`config/recurring.yml`), and each project has a **Sync now** button.

The sync only ever writes the English base columns — GitHub's descriptions and release notes
are English, and the German copy is yours. Fields ticked under **Protected from GitHub sync**
on a project are never overwritten once they have content, so hand-written copy survives.
Failures are recorded on the project and shown in the admin rather than retried forever.

## Deployment

Kamal to the Hetzner server that already runs `elbcasts.dev`, `pagebee.io` and
`headlessbee.com`. They share one `kamal-proxy`, which terminates TLS and routes by host,
so this app only claims `mathiaskarstaedt.de` and `www.mathiaskarstaedt.de`. Both already
resolve to the server, so Let's Encrypt issues the certificate on the first deploy.

The server is addressed over Tailscale (`100.106.129.53`, public `46.224.108.246`), and the
image is built on the server itself — the Mac is arm64 and cross-building a Rails image with
native gems under emulation is slow.

Set up once:

```sh
cp .env.example .env     # KAMAL_REGISTRY_PASSWORD = GitHub PAT with write:packages
direnv allow
```

`config/master.key` stays out of git and is read straight from disk by `.kamal/secrets`.

```sh
bin/kamal setup      # first deploy
bin/kamal deploy     # afterwards
bin/kamal logs -f
bin/kamal console
bin/kamal proxy logs -f   # TLS / routing
```

Commit before deploying — Kamal uses the git SHA as the image version.

Everything that is not in git lives in `/rails/storage` on the server, mounted from the
`mathiaskarstaedt_storage` volume: the SQLite databases (app, queue, cache, cable) and the
Active Storage uploads. That one volume is the entire backup surface.

```sh
bin/backup           # → backups/mathiaskarstaedt-YYYYMMDD-HHMM.tar.gz
```

The databases are snapshotted with `sqlite3 .backup` rather than copied off disk, so a write
in flight cannot produce a torn copy. Pair it with a Hetzner volume snapshot for off-site cover.

Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA`), so there is one container and no
accessory to look after.

## Design

The pages follow two design artifacts (home and project detail). Their colours, type scale and
spacing live as Tailwind theme tokens in `app/assets/tailwind/application.css` — a repaint
happens there and nowhere else. The three fonts (Bricolage Grotesque, Inter, JetBrains Mono)
are self-hosted in `app/assets/fonts`, so a visitor's browser never talks to Google.
