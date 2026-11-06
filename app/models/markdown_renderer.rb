# Renders the Markdown that project descriptions and release notes are written in.
# No raw HTML passes through: the copy comes from the admin, but release notes come
# straight from GitHub, so it is treated as untrusted either way.
#
# Named MarkdownRenderer rather than Markdown because Redcarpet already claims the
# top-level Markdown constant.
class MarkdownRenderer
  RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true, link_attributes: { rel: "noopener" }),
    autolink: true, tables: true, fenced_code_blocks: true, strikethrough: true,
    space_after_headers: true, no_intra_emphasis: true
  )

  def self.render(text)
    return nil if text.blank?

    RENDERER.render(text).html_safe
  end
end
