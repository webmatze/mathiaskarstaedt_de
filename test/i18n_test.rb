require "test_helper"

# A key that exists in one language and not the other shows up as
# "translation missing" on a live page. Catch it here instead.
class I18nTest < ActiveSupport::TestCase
  # Rails already ships English month and day names; only German needs its own.
  RAILS_PROVIDED = %w[
    date.month_names date.abbr_month_names date.day_names date.abbr_day_names
    time.month_names time.abbr_month_names time.day_names time.abbr_day_names
  ].freeze

  test "English and German define exactly the same keys" do
    missing_in_german = key_set(:en) - key_set(:de)
    missing_in_english = key_set(:de) - key_set(:en)

    assert_empty missing_in_german, "Keys missing from German: #{missing_in_german.sort.join(", ")}"
    assert_empty missing_in_english, "Keys missing from English: #{missing_in_english.sort.join(", ")}"
  end

  private
    # Only the app's own locale files — Rails' own translations are not ours to balance.
    def key_set(locale)
      Dir[Rails.root.join("config/locales/**/#{locale}.yml")].flat_map do |file|
        flatten_keys(YAML.load_file(file).fetch(locale.to_s))
      end.reject { |key| key.start_with?(*RAILS_PROVIDED) }.to_set
    end

    def flatten_keys(value, prefix = nil)
      return [ prefix ] unless value.is_a?(Hash)

      value.flat_map { |key, nested| flatten_keys(nested, [ prefix, key ].compact.join(".")) }
    end
end
