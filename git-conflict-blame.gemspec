# coding: utf-8
lib = File.expand_path( '../lib', __FILE__ )
$LOAD_PATH.unshift( lib ) unless $LOAD_PATH.include?( lib )
require 'git-conflict-blame/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-conflict-blame'
  spec.version       = GitConflictBlame::VERSION
  spec.authors       = ['Eric Terry']
  spec.email         = ['eterry1388@aol.com']

  spec.summary       = 'Git Conflict Blame'
  spec.description   = 'Git command that shows the blame on the lines that are in conflict'
  spec.homepage      = 'https://github.com/eterry1388/git-conflict-blame'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split( "\x0" ).reject { |f| f.match( %r{^(test|spec|features)/} ) }
  spec.executables   = spec.files.grep( %r{^bin/} ) { |f| File.basename( f ) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.3'

  spec.add_dependency 'rugged', '~> 0.23'
  spec.add_dependency 'colorize', '~> 0.7'
  spec.add_dependency 'nesty', '~> 1.0'
end
