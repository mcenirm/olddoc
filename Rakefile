# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
require 'tempfile'
include Rake::DSL
task :rsync_docs do
  dest = ENV["RSYNC_DEST"] || "80x24.org:/srv/80x24/olddoc/"
  top = %w(INSTALL README COPYING)

  # git-set-file-times is distributed with rsync,
  # Also available at: http://yhbt.net/git-set-file-times
  # on Debian systems: /usr/share/doc/rsync/scripts/git-set-file-times.gz
  sh("git", "set-file-times", 'Documentation', *top)

  do_gzip = lambda do |txt|
    gz = "#{txt}.gz"
    tmp = "#{gz}.#$$"
    sh("gzip --rsyncable -9 < #{txt} > #{tmp}")
    st = File.stat(txt)
    File.utime(st.atime, st.mtime, tmp) # make nginx gzip_static happy
    File.rename(tmp, gz)
    gz
  end

  files = `git ls-files Documentation/*.txt`.split(/\n/)
  files.concat(top)
  files.concat(%w(NEWS NEWS.atom.xml))
  gzfiles = files.map { |txt| do_gzip.call(txt) }
  files.concat(gzfiles)
  sh("rsync --chmod=Fugo=r -av #{files.join(' ')} #{dest}")
end
