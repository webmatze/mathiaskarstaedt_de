# Starting content, taken from the design draft. English lives in the columns,
# the German copy from the design lives in `translations`, so the second language
# is real from the first boot. Everything starts unpublished except the handful
# that already have finished copy.

SiteProfile.current.update!(
  terminal_prompt: "~/projects $ ls --sort=new",
  hero_headline: "Web apps, Mac apps, CLI tools and games. Built in Hamburg.",
  hero_intro: "I'm Mathias “Matze” Karstädt, a Ruby on Rails developer. Evenings and weekends I build the things I want to use myself — all of it in one place, from a comic reader for macOS to a 3D engine in pure Ruby.",
  about_headline: "Day job Rails. Nights everything else.",
  about_body: "At work I build Rails backends running on Kubernetes. In my own time I chase whatever has my attention: native Mac apps in Swift, terminal tools in Rust and Crystal, games with DragonRuby — and screencasts about all of it on Elbcasts.",
  skills: "Ruby on Rails, Swift / SwiftUI, Crystal, Rust, DragonRuby, Kubernetes",
  accent_color: "#D4F25A",
  translations: {
    "de" => {
      "terminal_prompt" => "~/projekte $ ls --sort=neu",
      "hero_headline" => "Web-Apps, Mac-Apps, CLI-Tools und Spiele. Gebaut in Hamburg.",
      "hero_intro" => "Ich bin Mathias „Matze“ Karstädt, Ruby-on-Rails-Entwickler. Abends und am Wochenende entstehen Dinge, die ich selbst benutzen will – hier ist alles an einem Ort, vom Comic-Reader für macOS bis zur 3D-Engine in purem Ruby.",
      "about_headline" => "Tagsüber Rails. Nachts alles andere.",
      "about_body" => "Beruflich baue ich als Senior-Rails-Entwickler Backends, die auf Kubernetes laufen. Privat probiere ich aus, was mich gerade reizt: native Mac-Apps in Swift, Terminal-Tools in Rust und Crystal, Spiele mit DragonRuby – und Screencasts darüber auf Elbcasts."
    }
  }
)

def upsert_project(slug, attributes)
  Project.find_or_initialize_by(slug: slug).tap do |project|
    project.assign_attributes(attributes)
    project.save!
  end
end

# --- Krazoom: the reference project, filled in completely. ---------------------
krazoom = upsert_project("krazoom",
  name: "Krazoom",
  kind: "desktop",
  status: "active",
  published: true,
  featured: true,
  featured_position: 1,
  platforms: "macOS",
  tech_stack: "Swift · SwiftUI",
  price: "Free",
  license: "Proprietary",
  formats: "CBZ, CBR, PDF, folders",
  homepage_url: "https://krazoom.app/",
  source_url: "https://github.com/webmatze/krazoom",
  github_repo: "webmatze/krazoom",
  last_activity_at: Date.new(2026, 10, 20),
  tagline: "Read your comics the way they were meant to be read. A native comic reader for macOS — free, no account, no tracking.",
  description: <<~MD,
    Krazoom opens your comics right where they live — CBZ, CBR, PDF or just a folder full of images. No import, no conversion, no account. The library scans your folders on its own, remembers where you left off, and sorts itself through saved searches.

    The highlight is the new panel mode: Krazoom detects the panels on each page locally on your Mac and walks you through the story frame by frame. `P` toggles it, `↑` shows the whole page again.
  MD
  translations: {
    "de" => {
      "tagline" => "Lies deine Comics so, wie sie gedacht sind. Ein nativer Comic-Reader für macOS – kostenlos, ohne Account, ohne Tracking.",
      "description" => <<~MD
        Krazoom öffnet deine Comics direkt dort, wo sie liegen – CBZ, CBR, PDF oder einfach ein Ordner voller Bilder. Kein Import, keine Konvertierung, kein Konto. Die Bibliothek scannt deine Ordner automatisch, merkt sich, wo du aufgehört hast, und lässt sich über gespeicherte Suchen sortieren.

        Das Highlight ist der neue Panel-Modus: Krazoom erkennt die Panels jeder Seite lokal auf deinem Mac und führt dich Bild für Bild durch die Geschichte. `P` schaltet um, `↑` zeigt die ganze Seite.
      MD
    }
  })

krazoom_features = [
  [ "Panel mode", "Detects the panels on every page — locally, no cloud.",
    "Panel-Modus", "Erkennt Panels auf jeder Seite – lokal, ohne Cloud." ],
  [ "Every common format", "CBZ, CBR, PDF and image folders, with no import step.",
    "Alle gängigen Formate", "CBZ, CBR, PDF und Bildordner, ohne Importschritt." ],
  [ "Smart library", "Automatic scanning, saved searches, reading progress.",
    "Smarte Bibliothek", "Automatisches Scannen, gespeicherte Suchen, Lesefortschritt." ],
  [ "Single and double page", "Keyboard navigation, swipe gestures, click to turn.",
    "Einzel- und Doppelseite", "Tastatur-Navigation, Wisch-Gesten, Klick zum Blättern." ],
  [ "Zoom however you like", "Pinch zoom and double-click zoom right into the detail.",
    "Zoom, wie du willst", "Pinch-Zoom und Doppelklick-Zoom bis ins Detail." ],
  [ "Private by design", "No subscriptions, no ads, no tracking, no account.",
    "Privat by Design", "Keine Abos, keine Werbung, kein Tracking, kein Account." ]
]

krazoom_features.each_with_index do |(title, body, de_title, de_body), index|
  feature = krazoom.features.find_or_initialize_by(title: title)
  feature.update!(body: body, position: index + 1,
    translations: { "de" => { "title" => de_title, "body" => de_body } })
end

[
  { title: "New: panel mode", version: "1.2.0", released_on: Date.new(2026, 10, 20), state: "released",
    body: "Panels are detected locally, page by page. Toggle with P, press ↑ to get back to the full page.",
    de: { "title" => "Neu: Panel-Modus", "body" => "Panels werden lokal pro Seite erkannt. Mit P umschalten, mit ↑ zurück zur ganzen Seite." } },
  { title: "Saved searches and reading progress", version: "1.1.0", released_on: Date.new(2026, 8, 14), state: "released",
    body: "The library remembers where you stopped and lets you keep searches around.",
    de: { "title" => "Gespeicherte Suchen und Lesefortschritt", "body" => "Die Bibliothek merkt sich, wo du aufgehört hast, und behält deine Suchen." } },
  { title: "Pro features: cloud sync and collections", state: "planned",
    body: "Coming soon — the base version stays free.",
    de: { "title" => "Pro-Funktionen: Cloud-Sync und Sammlungen", "body" => "Kommt bald – die Grundversion bleibt kostenlos." } }
].each do |attributes|
  german = attributes.delete(:de)
  update = krazoom.updates.find_or_initialize_by(title: attributes[:title])
  update.update!(**attributes, translations: { "de" => german })
end

[
  [ "Website", "https://krazoom.app/" ],
  [ "Source code", "https://github.com/webmatze/krazoom" ],
  [ "Compared with the alternatives", "https://krazoom.app/alternatives/" ]
].each_with_index do |(label, url), index|
  link = krazoom.links.find_or_initialize_by(url: url)
  link.update!(label: label, position: index + 1)
end

krazoom.downloads.find_or_initialize_by(url: "https://github.com/webmatze/krazoom/releases")
  .update!(label: "Download for macOS", version: "1.2.0", file_type: "dmg",
           architecture: "Apple Silicon", featured: true,
           translations: { "de" => { "label" => "Für macOS laden" } })

# --- The remaining projects from the design draft. ----------------------------
PROJECTS = [
  { slug: "elbcasts", name: "Elbcasts", kind: "website", status: "active",
    published: true, featured: true, featured_position: 2,
    homepage_url: "https://elbcasts.dev/", tech_stack: "Rails",
    last_activity_at: Date.new(2026, 11, 2),
    tagline: "Short screencasts, real code, straight from the terminal. Recorded in Hamburg, two to three new episodes a week — self-hosted as a Rails app.",
    de: { "tagline" => "Kurze Screencasts, echter Code, direkt aus dem Terminal. Aufgenommen in Hamburg, 2–3 neue Folgen pro Woche – selbst gehostet als Rails-App." } },

  { slug: "smith", name: "smith", kind: "cli", status: "active",
    published: true, featured: true, featured_position: 3,
    source_url: "https://github.com/webmatze/smith", github_repo: "webmatze/smith",
    tech_stack: "Crystal", last_activity_at: Date.new(2026, 10, 28),
    tagline: "A fast, local-first harness for LLM agents, written in Crystal. It also drives my code review bot.",
    de: { "tagline" => "Ein schneller, local-first Harness für LLM-Agenten, geschrieben in Crystal. Treibt auch meinen Code-Review-Bot an." } },

  { slug: "fabelhaft", name: "Fabelhaft", kind: "cli", status: "active",
    published: true, featured: true, featured_position: 4,
    homepage_url: "https://webmatze.github.io/fabelhaft/", github_repo: "webmatze/fabelhaft",
    tech_stack: "Python", last_activity_at: Date.new(2026, 10, 25),
    tagline: "A writing studio in the terminal: Scrivener-like structure, distraction-free focus, and plain Markdown files that stay yours forever.",
    de: { "tagline" => "Ein Schreibstudio im Terminal: Struktur wie in Scrivener, ablenkungsfreier Fokus und reine Markdown-Dateien, die dir für immer gehören." } },

  { slug: "libghostty-terminal", name: "libghostty-terminal", kind: "desktop", status: "active",
    tech_stack: "C · SDL2", last_activity_at: Date.new(2026, 11, 3),
    github_repo: "webmatze/libghostty-terminal",
    tagline: "A terminal window in a single C file, built on libghostty-vt and SDL2. The demo from an Elbcasts episode.",
    de: { "tagline" => "Ein Terminalfenster in einer einzigen C-Datei, gebaut auf libghostty-vt und SDL2. Die Demo aus einer Elbcasts-Folge." } },

  { slug: "pagebee", name: "PageBee", kind: "webapp", status: "active",
    homepage_url: "https://pagebee.io/", tech_stack: "Waiting list open",
    last_activity_at: Date.new(2026, 11, 1),
    tagline: "A no-code website builder: pick your sections, adjust colours and fonts, publish with one click.",
    de: { "tagline" => "No-Code-Baukasten für Webseiten: Sektionen auswählen, Farben und Schriften anpassen, mit einem Klick veröffentlichen." } },

  { slug: "honigflug", name: "Honigflug", kind: "game", status: "active",
    tech_stack: "Ruby · DragonRuby", last_activity_at: Date.new(2026, 10, 18),
    tagline: "A bee simulation for the DragonRuby Game Toolkit.",
    de: { "tagline" => "Eine Bienen-Simulation für das DragonRuby Game Toolkit." } },

  { slug: "adventure-game-engine", name: "Adventure Game Engine", kind: "library", status: "active",
    tech_stack: "Ruby · DragonRuby", last_activity_at: Date.new(2026, 10, 16),
    tagline: "A data-driven engine for 2D point-and-click adventures on top of the DragonRuby Game Toolkit.",
    de: { "tagline" => "Datengetriebene Engine für 2D-Point-and-Click-Adventures auf Basis des DragonRuby Game Toolkit." } },

  { slug: "comicmation", name: "comicmation", kind: "library", status: "active",
    github_repo: "webmatze/comicmation", tech_stack: "Swift · Library + CLI",
    last_activity_at: Date.new(2026, 10, 14),
    tagline: "Finds pages, page numbers, panels and speech balloons with their text in comic images — entirely on device.",
    de: { "tagline" => "Findet Seiten, Seitenzahlen, Panels und Sprechblasen samt Text in Comic-Bildern – komplett auf dem Gerät." } },

  { slug: "writepal", name: "Writepal", kind: "webapp", status: "active",
    tech_stack: "Rails · Ollama", last_activity_at: Date.new(2026, 10, 12),
    tagline: "A Rails app that gives writing a book some structure — with AI support from local models in Ollama.",
    de: { "tagline" => "Rails-App, die das Schreiben eines Buches strukturiert – mit KI-Unterstützung über lokale Modelle in Ollama." } },

  { slug: "d3d-pro", name: "d3d-pro", kind: "library", status: "active",
    homepage_url: "https://webmatze.itch.io/d3d-pro", tech_stack: "Ruby · C extension",
    last_activity_at: Date.new(2026, 10, 10),
    tagline: "A software 3D engine for DragonRuby in pure Ruby: models, voxel worlds and 6DOF scenes, optionally accelerated in C.",
    de: { "tagline" => "Software-3D-Engine für DragonRuby in purem Ruby: Modelle, Voxelwelten und 6DOF-Szenen, optional mit C-Beschleunigung." } },

  { slug: "shoebox", name: "Shoebox", kind: "desktop", status: "active",
    tech_stack: "C++ · Haiku", last_activity_at: Date.new(2026, 10, 6),
    tagline: "A photo organiser for the Haiku operating system, built directly on what the BFS file system can do.",
    de: { "tagline" => "Ein Foto-Organizer für das Betriebssystem Haiku, der direkt auf den Fähigkeiten des BFS-Dateisystems aufbaut." } },

  { slug: "core-breach", name: "Core Breach", kind: "game", status: "active",
    tech_stack: "Ruby · d3d", last_activity_at: Date.new(2026, 9, 26),
    tagline: "A six-degrees-of-freedom mine shooter in pure Ruby, built with DragonRuby and my own d3d engine.",
    de: { "tagline" => "Minen-Shooter mit sechs Freiheitsgraden in purem Ruby, gebaut mit DragonRuby und der eigenen d3d-Engine." } },

  { slug: "code-review-smith", name: "code-review-smith", kind: "cli", status: "active",
    github_repo: "webmatze/code-review-smith", tech_stack: "Crystal",
    last_activity_at: Date.new(2026, 9, 20),
    tagline: "An LLM code review bot for GitHub and GitLab: a summary plus inline comments in the diff, powered by smith.",
    de: { "tagline" => "LLM-Code-Review-Bot für GitHub und GitLab: Zusammenfassung plus Inline-Kommentare im Diff, angetrieben von smith." } },

  { slug: "familyhub", name: "FamilyHub", kind: "mobile", status: "active",
    tech_stack: "Kotlin · Android", last_activity_at: Date.new(2026, 9, 14),
    tagline: "An Android app for the family.",
    de: { "tagline" => "Android-App für die Familie." } },

  { slug: "try-haiku", name: "try-haiku", kind: "desktop", status: "active",
    github_repo: "webmatze/try-haiku", tech_stack: "Swift · macOS",
    last_activity_at: Date.new(2026, 9, 8),
    tagline: "Boots the Haiku ARM64 nightly on Apple Silicon Macs from a signed app — unofficial, built from source.",
    de: { "tagline" => "Startet das Haiku-ARM64-Nightly auf Apple-Silicon-Macs aus einer signierten App heraus – inoffiziell, aus dem Quellcode gebaut." } },

  { slug: "default-browser-switcher", name: "Default Browser Switcher", kind: "desktop", status: "maintained",
    github_repo: "webmatze/default-browser-switcher", tech_stack: "Swift · macOS",
    last_activity_at: Date.new(2026, 7, 2),
    tagline: "A lean menu bar app for macOS: switch your default browser with one click.",
    de: { "tagline" => "Schlanke Menüleisten-App für macOS: Standardbrowser mit einem Klick wechseln." } }
]

PROJECTS.each do |attributes|
  attributes = attributes.dup
  german = attributes.delete(:de)
  slug = attributes.delete(:slug)
  upsert_project(slug, attributes.merge(translations: { "de" => german }))
end

# Krazoom's related projects, as in the design.
%w[ comicmation default-browser-switcher try-haiku ].each_with_index do |slug, index|
  related = Project.find_by(slug: slug)
  next unless related

  krazoom.relations.find_or_create_by!(related_project: related) { |relation| relation.position = index + 1 }
end

# Publish the ones whose copy is already finished.
Project.where(slug: PROJECTS.map { |p| p[:slug] }).update_all(published: true)

if (email = ENV["ADMIN_EMAIL"]).present?
  User.find_or_create_by!(email_address: email) do |user|
    user.password = ENV.fetch("ADMIN_PASSWORD")
  end
  puts "Admin user: #{email}"
end

puts "Seeded #{Project.count} projects (#{Project.published.count} published)."
