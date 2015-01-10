# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
module Olddoc
  VERSION = '1.0.1'

  autoload :Gemspec, 'olddoc/gemspec'
  autoload :History, 'olddoc/history'
  autoload :Merge, 'olddoc/merge'
  autoload :NewsAtom, 'olddoc/news_atom'
  autoload :NewsRdoc, 'olddoc/news_rdoc'
  autoload :Prepare, 'olddoc/prepare'
  autoload :Readme, 'olddoc/readme'

  def self.config(path = ".olddoc.yml")
    File.readable?(path) and return YAML.load(File.read(path))
    warn "#{path} not found in current directory"
    {}
  end
end
require_relative 'oldweb'
