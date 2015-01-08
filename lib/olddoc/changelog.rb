# helper method for generating the ChangeLog in RDoc format atomically
require 'tempfile'

module Olddoc::Changelog
  include Olddoc::History

  def changelog
    fp = Tempfile.new('ChangeLog', '.')
    fp.write "ChangeLog from #@cgit_uri"
    cmd = %w(git log)
    if @changelog_start && tags[0]
      range = "#@changelog_start..#{tags[0][:tag]}"
      fp.write(" (#{range})")
      cmd << range
    end
    fp.write("\n\n")
    prefix = "   "
    IO.popen(cmd.join(' ')) do |io|
      io.each { |line|
        fp.write prefix
        fp.write line
      }
    end
    fp.chmod(0666 & ~File.umask)
    File.rename(fp.path, 'ChangeLog')
    fp.close!
  end
end
