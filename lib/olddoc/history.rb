# Copyright (C) 2015, all contributors <olddoc-public@80x24.org>
# License: GPLv3 or later (https://www.gnu.org/licenses/gpl-3.0.txt)
require 'uri'

module Olddoc::History
  def initialize_history
    @tags = @old_summaries = nil
  end

  # returns a cgit URI for a given +tag_name+
  def tag_uri(tag_name)
    uri = @cgit_uri.dup
    uri.path += "/tag/"
    uri.query = "id=#{tag_name}"
    uri
  end

  def tags
    timefmt = '%Y-%m-%dT%H:%M:%SZ'
    @tags ||= `git tag -l`.split(/\n/).map do |tag|
      next if tag == "v0.0.0"
      if %r{\Av[\d\.]+} =~ tag
        type = `git cat-file -t #{tag}`.chomp
        user_type = { "tag" => "tagger", "commit" => "committer" }[type]
        user_type or abort "unable to determine what to do with #{type}=#{tag}"
        header, subject, body = `git cat-file #{type} #{tag}`.split(/\n\n/, 3)
        body ||= "initial" unless old_summaries.include?(tag)
        header = header.split(/\n/)

        tagger = header.grep(/\A#{user_type} /).first
        time = Time.at(tagger.split(/ /)[-2].to_i).utc
        {
          :time => time.strftime(timefmt),
          :ruby_time => time,
          :tagger_name => %r{^#{user_type} ([^<]+)}.match(tagger)[1].strip,
          :tagger_email => %r{<([^>]+)>}.match(tagger)[1].strip,
          :id => `git rev-parse refs/tags/#{tag}`.chomp!,
          :tag => tag,
          :subject => subject.strip,
          :body => (old = old_summaries[tag]) ? "#{old}\n#{body}" : body,
        }
      end
    end.compact.sort { |a,b| b[:time] <=> a[:time] }
  end

  def old_summaries
    @old_summaries ||= if File.exist?(".CHANGELOG.old")
      File.readlines(".CHANGELOG.old").inject({}) do |hash, line|
        version, summary = line.split(/ - /, 2)
        hash[version] = summary
        hash
      end
    else
      {}
    end
  end
end
