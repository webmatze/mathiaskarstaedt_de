class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string  :slug,             null: false
      t.string  :name,             null: false
      t.string  :tagline
      t.text    :description
      t.string  :kind,             null: false
      t.string  :status,           null: false, default: "active"

      # Fact-sheet fields, free text on purpose: every kind of project needs
      # slightly different words here.
      t.string  :platforms
      t.string  :tech_stack
      t.string  :price
      t.string  :license
      t.string  :formats

      t.boolean :published,        null: false, default: false
      t.boolean :featured,         null: false, default: false
      t.integer :featured_position
      t.integer :position

      # Drives the "latest projects" order. Filled from GitHub when connected,
      # editable by hand otherwise.
      t.datetime :last_activity_at

      t.string   :homepage_url
      t.string   :source_url

      # GitHub connection
      t.string   :github_repo
      t.datetime :github_synced_at
      t.string   :github_sync_error
      t.integer  :github_stars
      t.json     :locked_fields,   null: false, default: []

      # German (and any future locale) copy for the translatable fields.
      t.json     :translations,    null: false, default: {}

      t.timestamps
    end

    add_index :projects, :slug, unique: true
    add_index :projects, :github_repo, unique: true, where: "github_repo IS NOT NULL"
    add_index :projects, [ :published, :last_activity_at ]
    add_index :projects, [ :published, :featured, :featured_position ]
  end
end
