# One place that knows what a project kind looks like: its label, its colour and
# its icon. The badge on a card, the legend on the home page and the filter chips
# all read from here, so adding a kind is a one-line change.
class ProjectKind
  ALL = %w[ website webapp desktop mobile cli game library ].freeze

  COLORS = {
    "website" => "#7CC4FF",
    "webapp"  => "#5EE0C0",
    "desktop" => "#FFB35C",
    "mobile"  => "#FF8FB1",
    "cli"     => "#D4F25A",
    "game"    => "#B79CFF",
    "library" => "#C9CED3"
  }.freeze

  attr_reader :key

  def self.all
    ALL.map { |key| new(key) }
  end

  def self.find(key)
    new(key.to_s) if ALL.include?(key.to_s)
  end

  def initialize(key)
    @key = key.to_s
  end

  def label
    I18n.t("project_kinds.#{key}")
  end

  def color
    COLORS.fetch(key, COLORS["library"])
  end

  # Tinted pill background for the badge — the designs use 12% of the kind colour.
  def tint
    "color-mix(in srgb, #{color} 12%, transparent)"
  end

  def ==(other)
    other.is_a?(ProjectKind) && other.key == key
  end

  def to_s
    key
  end
end
