# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
$LOAD_PATH << 'lib'
require 'olddoc'
extend Olddoc::Gemspec
name, summary, title = readme_metadata
Gem::Specification.new do |s|
  manifest = File.read('.gem-manifest').split(/\n/)
  s.name = 'olddoc'
  s.version = Olddoc::VERSION
  s.executables = %w(olddoc)
  s.authors = ["#{s.name} hackers"]
  s.summary = summary
  s.description = readme_description
  s.email = Olddoc.config['private_email']
  s.files = manifest
  s.add_dependency('rdoc', '~> 4.2')
  s.add_dependency('builder', '~> 3.2')
  s.homepage = Olddoc.config['rdoc_url']
  s.licenses = 'GPLv3+'
end
