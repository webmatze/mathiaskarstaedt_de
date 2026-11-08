class CreatePodcasts < ActiveRecord::Migration[8.1]
  def change
    create_table :podcasts do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.string :tagline
      t.text :description
      t.string :author
      t.string :owner_email
      t.string :language, default: "de", null: false
      t.string :category, default: "Technology", null: false
      t.boolean :explicit, default: false, null: false
      t.boolean :published, default: false, null: false
      t.integer :position
      t.string :youtube_url
      t.string :spotify_url
      t.string :apple_url
      t.string :accent_color
      t.json :translations, default: {}, null: false

      t.timestamps
    end
    add_index :podcasts, :slug, unique: true
    add_index :podcasts, [ :published, :position ]

    create_table :podcast_episodes do |t|
      t.references :podcast, null: false, foreign_key: true
      t.string :slug, null: false
      t.integer :number
      t.string :title, null: false
      t.text :summary
      t.text :show_notes
      t.text :transcript
      t.string :youtube_url
      t.datetime :published_at
      t.integer :duration_seconds
      t.boolean :explicit, default: false, null: false
      t.boolean :published, default: false, null: false
      t.json :translations, default: {}, null: false

      t.timestamps
    end
    add_index :podcast_episodes, [ :podcast_id, :slug ], unique: true
    add_index :podcast_episodes, [ :podcast_id, :published, :published_at ]
  end
end
