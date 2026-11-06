# mathiaskarstaedt.de

The portfolio behind [mathiaskarstaedt.de](https://mathiaskarstaedt.de): one place for the
web apps, Mac apps, CLI tools, games and libraries that are otherwise scattered across
GitHub, itch.io and their own landing pages.

- **Home** — hero, favourites, every published project ordered by last activity, filterable
  by type. The type (website, web app, desktop, mobile, CLI, game, library) is readable at a
  glance from a coloured badge, and the colours come from one place: `app/models/project_kind.rb`.
- **Project pages** — screenshots, description, features, an update timeline, downloads,
  a fact sheet, links and related projects.
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

Kamal to a single Hetzner VPS. Before the first deploy, set the server IP in
`config/deploy.yml` and point the DNS A/AAAA records at it.

```bash
bin/kamal setup      # first time
bin/kamal deploy     # afterwards
bin/kamal logs -f
bin/kamal console
```

Everything that is not in git lives in `/rails/storage` on the server, mounted from the
`mathiaskarstaedt_storage` volume: the SQLite databases (app, queue, cache, cable) and the
Active Storage uploads. That one volume is the entire backup surface.

```bash
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
