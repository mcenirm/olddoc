# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
require 'builder'

module Olddoc::NewsAtom
  include Olddoc::History
  include Olddoc::Readme

  # generates an Atom feed based on git tags in the document directory
  def news_atom_xml
    project_name, short_desc, _ = readme_metadata
    new_tags = tags[0,10]
    atom_uri = @rdoc_uri.dup
    atom_uri.path += "NEWS.atom.xml"
    news_uri = @rdoc_uri.dup
    news_uri.path += "NEWS.html"
    x = Builder::XmlMarkup.new
    x.feed(xmlns: "http://www.w3.org/2005/Atom") do
      x.id(atom_uri.to_s)
      x.title("#{project_name} news")
      x.subtitle(short_desc)
      x.link(rel: 'alternate', type: 'text/html', href: news_uri.to_s)
      x.updated(new_tags.empty? ? '1970-01-01:00:00:00Z' : new_tags[0][:time])
      new_tags.each do |tag|
        x.entry do
          x.title(tag[:subject])
          x.updated(tag[:time])
          x.published(tag[:time])
          x.author do
            x.name(tag[:tagger_name])
            x.email(tag[:tagger_email])
          end
          uri = tag_uri(tag[:tag]).to_s
          x.link(rel: "alternate", type: 'text/html', href: uri)
          x.id(uri)
          x.content(type: :xhtml) { x.pre(tag[:body]) }
        end # entry
      end # new_tags
    end # feed
    [ x.target!, new_tags ]
  end

  def news_atom(dest = "NEWS.atom.xml")
    xml, new_tags = news_atom_xml
    File.open(dest, "w") { |fp| fp.write(xml) }
    unless new_tags.empty?
      time = new_tags[0][:ruby_time]
      File.utime(time, time, dest)
    end
  end
end
