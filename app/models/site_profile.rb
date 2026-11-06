# The copy on the home page that is not a project: hero, about, legal pages and
# the accent colour. A singleton — there is only ever one site.
class SiteProfile < ApplicationRecord
  include Translatable

  translates :terminal_prompt, :hero_headline, :hero_intro,
    :about_headline, :about_body, :imprint_body, :privacy_body

  validates :accent_color, format: { with: /\A#[0-9A-Fa-f]{6}\z/ }

  def self.current
    first || create!
  end

  def skill_list
    skills.to_s.split(",").map(&:strip).compact_blank
  end
end
