# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)

class Olddoc::Merge
  def initialize(opts)
    @merge_html = opts["merge_html"] || {}
  end

  # FIXME: generate manpages directly from rdoc instead of relying on
  # pandoc to do it via markdown.
  def run
    @merge_html.each do |file, source|
      rdoc_html = "doc/#{file}.html"
      fragment = File.read(source)
      File.open(rdoc_html, "a+") { |fp|
        html = fp.read
        if html.sub!(%r{\s*<p>\s*olddoc_placeholder\s*</p>\s*}sm, fragment)
          fp.truncate(0)
          fp.write(html)
        else
          warn "olddoc_placeholder not found in #{rdoc_html}"
        end
      }
    end
  end
end
