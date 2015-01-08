# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)

require 'uri'
class Olddoc::Prepare
  include Olddoc::NewsRdoc
  include Olddoc::NewsAtom
  include Olddoc::Changelog
  include Olddoc::Readme

  def initialize(opts)
    rdoc_url = opts['rdoc_url']
    cgit_url = opts['cgit_url']
    rdoc_url && cgit_url or
      abort "rdoc_url and cgit_url required in .olddoc.yml for `prepare'"
    @rdoc_uri = URI.parse(rdoc_url)
    @cgit_uri = URI.parse(cgit_url)
    @changelog_start = opts['changelog_start']
    @name, @short_desc = readme_metadata
  end

  def run
    news_rdoc
    changelog
    news_atom
  end
end
