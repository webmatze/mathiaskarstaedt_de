require "test_helper"

class TranslatableTest < ActiveSupport::TestCase
  test "localized reader returns English by default" do
    assert_equal "A native comic reader for macOS.", projects(:krazoom).localized_tagline
  end

  test "localized reader returns the German text when the locale is German" do
    I18n.with_locale(:de) do
      assert_equal "Ein nativer Comic-Reader für macOS.", projects(:krazoom).localized_tagline
    end
  end

  test "a missing translation falls back to English" do
    I18n.with_locale(:de) do
      assert_equal "A no-code website builder.", projects(:pagebee).localized_tagline
    end
  end

  test "blank translations are dropped so the field falls back again" do
    project = projects(:krazoom)
    project.update!(translations: { "de" => { "tagline" => "  ", "description" => "Immer noch da." } })

    I18n.with_locale(:de) do
      assert_equal "A native comic reader for macOS.", project.localized_tagline
      assert_equal "Immer noch da.", project.localized_description
    end
  end

  test "English is never stored as a translation" do
    project = projects(:pagebee)
    project.update!(translations: { "en" => { "tagline" => "should be ignored" }, "de" => { "tagline" => "Baukasten" } })

    assert_equal %w[ de ], project.translations.keys
  end

  test "counts translated fields for the admin overview" do
    assert_equal 2, projects(:krazoom).translated_field_count(:de)
    assert_equal 2, projects(:krazoom).translatable_field_count
    assert_equal 0, projects(:pagebee).translated_field_count(:de)
  end

  test "nested records translate too" do
    I18n.with_locale(:de) do
      assert_equal "Panel-Modus", project_features(:panel_mode).localized_title
      assert_equal "Every common format", project_features(:formats).localized_title
    end
  end
end
