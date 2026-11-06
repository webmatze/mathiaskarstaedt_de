module ProjectsHelper
  # The pill that says what a project is. One per kind, tinted with the kind's colour.
  def kind_badge(kind, extra: nil, **options)
    return if kind.nil?

    tag.span(**options, class: [ "inline-flex items-center gap-2 rounded-full px-[11px] py-[5px] font-mono text-xs font-medium tracking-[0.04em] uppercase", options[:class] ],
      style: "background: #{kind.tint}; color: #{kind.color}") do
      safe_join([ kind_dot(kind), [ kind.label, extra ].compact_blank.join(" · ") ])
    end
  end

  def kind_dot(kind)
    tag.span(class: "size-2 rounded-[2px]", style: "background: #{kind.color}", aria: { hidden: true })
  end

  def kind_swatch(kind)
    tag.span(class: "inline-block size-2.5 rounded-[3px]", style: "background: #{kind.color}", aria: { hidden: true })
  end

  # A neutral outlined pill, used for status and loose facts next to the kind badge.
  def meta_pill(label, dot_color: nil)
    tag.span(class: "inline-flex items-center gap-2 rounded-full border border-line-bright px-3 py-1.5 font-mono text-xs text-ink-soft") do
      safe_join([
        dot_color && tag.span(class: "size-2 rounded-full", style: "background: #{dot_color}", aria: { hidden: true }),
        label
      ].compact)
    end
  end

  def project_status_dot(project)
    project.status == "active" ? "#5EE0C0" : "#9AA3AB"
  end

  def project_kind_path(kind)
    kind ? projects_path(kind: kind.key) : projects_path
  end
end
