class CreateSiteProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :site_profiles do |t|
      t.string :terminal_prompt
      t.string :hero_headline
      t.text   :hero_intro
      t.string :about_headline
      t.text   :about_body
      t.string :skills
      t.string :accent_color, null: false, default: "#D4F25A"
      t.text   :imprint_body
      t.text   :privacy_body
      t.json   :translations, null: false, default: {}
      t.timestamps
    end
  end
end
