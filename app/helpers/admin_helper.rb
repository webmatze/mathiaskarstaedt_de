module AdminHelper
  FIELD_CLASS = "w-full rounded-lg border border-line-bright bg-canvas px-3 py-2.5 text-[15px] " \
                "text-ink placeholder:text-ink-ghost focus:border-line-muted focus:outline-none"

  def admin_field_class
    FIELD_CLASS
  end

  def admin_label_class
    "mb-1.5 block font-mono text-xs tracking-[0.06em] uppercase text-ink-meta"
  end

  # One labelled input. Keeps the form partials about structure, not about classes.
  def admin_field(form, attribute, as: :text_field, hint: nil, choices: nil, **options)
    input = if choices
      form.select(attribute, choices, { include_blank: options.delete(:include_blank) }, class: admin_field_class, **options)
    else
      form.public_send(as, attribute, class: admin_field_class, **options)
    end

    tag.div(class: "flex flex-col") do
      safe_join([
        form.label(attribute, class: admin_label_class),
        input,
        hint && tag.p(hint, class: "mt-1 text-xs text-ink-faint")
      ].compact)
    end
  end

  def admin_section(title, &block)
    tag.fieldset(class: "flex flex-col gap-5 rounded-2xl border border-line-strong bg-surface p-6") do
      safe_join([ tag.legend(title, class: "px-2 font-mono text-xs tracking-[0.08em] uppercase text-ink-meta"), capture(&block) ])
    end
  end

  # Picks the input for a nested field from the column type, so the nested form
  # partial can stay generic across features, screenshots, updates and the rest.
  def admin_nested_field(form, field)
    record = form.object

    case
    when field == :image
      admin_image_field(form)
    when field == :state
      admin_field form, field, choices: Project::Update::STATES.map { |state| [ t("projects.show.#{state == "planned" ? "planned" : "latest"}"), state ] }
    when record.class.columns_hash[field.to_s]&.type == :boolean
      tag.label(class: "flex items-center gap-2 self-end py-2.5 text-sm") do
        safe_join([ form.check_box(field, class: "size-4"), record.class.human_attribute_name(field) ])
      end
    when record.class.columns_hash[field.to_s]&.type == :text
      admin_field form, field, as: :text_area, rows: 3
    when record.class.columns_hash[field.to_s]&.type == :date
      admin_field form, field, as: :date_field
    when record.class.columns_hash[field.to_s]&.type.in?(%i[ integer bigint ])
      admin_field form, field, as: :number_field
    else
      admin_field form, field
    end
  end

  def admin_image_field(form)
    tag.div(class: "flex flex-col") do
      safe_join([
        form.label(:image, class: admin_label_class),
        form.object.image.attached? ? image_tag(form.object.image.variant(:thumb), class: "mb-2 h-20 w-auto rounded-lg") : "",
        form.file_field(:image, accept: "image/png,image/jpeg,image/webp", class: "text-sm text-ink-soft")
      ])
    end
  end

  # German inputs for a record's translatable fields. Named directly rather than
  # through fields_for, because the values live in a JSON column and not in an
  # associated object.
  def admin_translation_fields(form, rows: 2)
    record = form.object
    german = record.translation_for(:de)

    safe_join(record.class.translatable_fields.map do |field|
      name = "#{form.object_name}[translations][de][#{field}]"

      tag.div(class: "flex flex-col") do
        safe_join([
          label_tag(name, t("admin.projects.form.german_label", attribute: record.class.human_attribute_name(field)), class: admin_label_class),
          text_area_tag(name, german[field], rows: rows, class: admin_field_class)
        ])
      end
    end)
  end
end
