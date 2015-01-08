# -*- encoding: utf-8 -*-
# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)

require 'tempfile'

module Olddoc::NewsRdoc
  include Olddoc::History

  def puts_tag(fp, tag)
    time = tag[:time].tr('T', ' ').gsub!(/:\d\dZ/, ' UTC')
    fp.puts "=== #{tag[:subject]} / #{time}"
    fp.puts ""

    body = tag[:body]
    fp.puts tag[:body].gsub(/^/smu, "  ").gsub(/[ \t]+$/smu, "")
    fp.puts ""
  end

  # generates a NEWS file in the top-level directory based on git tags
  def news_rdoc
    news = Tempfile.new('NEWS', '.')
    tags.each { |tag| puts_tag(news, tag) }
    File.open("LATEST", "wb") { |latest|
      if tags.empty?
        latest.puts "Currently unreleased"
        news.puts "No news yet."
      else
        puts_tag(latest, tags[0])
      end
    }
    news.chmod(0666 & ~File.umask)
    File.rename(news.path, 'NEWS')
    news.close!
  end
end
