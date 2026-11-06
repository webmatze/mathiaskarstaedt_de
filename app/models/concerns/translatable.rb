# Translatable content fields without a translation gem.
#
# The shipped language (English) lives in the ordinary column. Every other locale
# lives in the record's `translations` JSON column:
#
#   { "de" => { "tagline" => "Lies deine Comics so, wie sie gedacht sind." } }
#
# Declaring `translates :tagline` keeps `tagline` as the raw English accessor and
# adds `localized_tagline`, which returns the current locale's text and falls back
# to English when it is missing. Views always ask for the localized reader.
module Translatable
  extend ActiveSupport::Concern

  BASE_LOCALE = :en

  class_methods do
    def translates(*names)
      translatable_fields.concat(names.map(&:to_s))

      names.each do |name|
        define_method(:"localized_#{name}") { localized(name) }
      end
    end

    def translatable_fields
      @translatable_fields ||= []
    end
  end

  # Translations arrive from the admin form as { "de" => { "tagline" => "…" } }.
  # Blank values are dropped so a cleared field falls back to English again.
  # Prepended so it wins over Active Record's generated attribute writer, which
  # it then reaches through `self[]=` rather than `super` — Active Record defines
  # that writer lazily, so `super` is not reliably there yet.
  module Writer
    def translations=(value)
      self[:translations] = sanitize_translations(value)
    end
  end

  included do
    prepend Writer
  end

  def localized(name, locale: I18n.locale)
    return self[name] if locale.to_sym == BASE_LOCALE

    translation_for(locale)[name.to_s].presence || self[name]
  end

  def translation_for(locale)
    translations&.fetch(locale.to_s, nil) || {}
  end

  # "3 of 7" — tells the admin at a glance how complete a locale is.
  def translated_field_count(locale)
    self.class.translatable_fields.count { |field| translation_for(locale)[field].present? }
  end

  def translatable_field_count
    self.class.translatable_fields.size
  end

  private
    def sanitize_translations(value)
      return {} if value.blank?

      value.to_h.each_with_object({}) do |(locale, fields), result|
        next if locale.to_s == BASE_LOCALE.to_s

        kept = fields.to_h.filter_map { |field, text| [ field.to_s, text ] if text.present? }.to_h
        result[locale.to_s] = kept if kept.any?
      end
    end
end
