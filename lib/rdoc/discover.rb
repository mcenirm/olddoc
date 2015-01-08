begin
  gem 'rdoc', '~> 4.1'
  require_relative '../olddoc'
rescue Gem::LoadError
end unless defined?(Olddoc)
