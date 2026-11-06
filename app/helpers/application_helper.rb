module ApplicationHelper
  def page_title(title = nil)
    [ title, t("site.name") ].compact_blank.join(" · ")
  end

  def markdown(text)
    MarkdownRenderer.render(text)
  end

  # "Nov 2026" in both locales — the format the design uses for every date chip.
  def month_year(date)
    l(date.to_date, format: :month_year) if date
  end

  # Same shape as link_to, including the block form, with the attributes an
  # outbound link should always carry.
  def external_link_to(name = nil, url = nil, **options, &block)
    if block
      link_to(name, **options, rel: "noopener", target: "_blank", &block)
    else
      link_to(name, url, **options, rel: "noopener", target: "_blank")
    end
  end
end
