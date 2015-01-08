# helper methods for gemspecs
module Olddoc::Gemspec
  include Olddoc::Readme

  def extra_rdoc_files(manifest)
    File.readlines('.document').map! do |x|
      x.chomp!
      if File.directory?(x)
        manifest.grep(%r{\A#{x}/})
      elsif File.file?(x)
        x
      else
        nil
      end
    end.flatten.compact
  end
end
