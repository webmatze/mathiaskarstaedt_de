class CreateProjectDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :project_features do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :title, null: false
      t.text    :body
      t.integer :position
      t.json    :translations, null: false, default: {}
      t.timestamps
    end

    create_table :project_screenshots do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :caption
      t.string  :video_url
      t.boolean :hero, null: false, default: false
      t.integer :position
      t.json    :translations, null: false, default: {}
      t.timestamps
    end

    create_table :project_updates do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :version
      t.string  :title, null: false
      t.text    :body
      t.date    :released_on
      t.string  :state, null: false, default: "released"
      t.string  :url
      t.bigint  :github_release_id
      t.json    :translations, null: false, default: {}
      t.timestamps
    end

    create_table :project_downloads do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :label
      t.string  :url, null: false
      t.string  :version
      t.string  :file_type
      t.string  :architecture
      t.bigint  :byte_size
      t.boolean :featured, null: false, default: false
      t.integer :position
      t.json    :translations, null: false, default: {}
      t.timestamps
    end

    create_table :project_links do |t|
      t.references :project, null: false, foreign_key: true
      t.string  :label, null: false
      t.string  :url, null: false
      t.string  :display_url
      t.integer :position
      t.json    :translations, null: false, default: {}
      t.timestamps
    end

    create_table :project_relations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :related_project, null: false, foreign_key: { to_table: :projects }
      t.integer :position
      t.timestamps
    end

    add_index :project_updates, [ :project_id, :github_release_id ], unique: true,
      where: "github_release_id IS NOT NULL", name: "index_project_updates_on_github_release"
    add_index :project_relations, [ :project_id, :related_project_id ], unique: true
  end
end
