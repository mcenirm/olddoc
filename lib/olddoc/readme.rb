# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)

# helpers for parsing the top-level README file
module Olddoc::Readme

  def readme_path
    'README'
  end

  # returns a one-paragraph summary from the README
  def readme_description
    File.read(readme_path).split(/\n\n/)[1]
  end

  # parses the README file in the top-level directory for project metadata
  def readme_metadata
    l = File.readlines(readme_path)[0].strip!
    l.gsub!(/^=\s+/, '') or abort "#{l.inspect} doesn't start with '='"
    title = l.dup
    if l.gsub!(/^(\w+\!)\s+/, '') # Rainbows!
      return $1, l, title
    else
      return (l.split(/\s*[:-]\s*/, 2)).push(title)
    end
  end
end
