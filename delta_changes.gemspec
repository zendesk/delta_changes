require_relative 'lib/delta_changes/version'

Gem::Specification.new 'delta_changes', DeltaChanges::VERSION do |s|
  s.summary = 'Additional real/virtual attribute change tracking independent of ActiveRecords'
  s.authors = ['Michael Grosser']
  s.email = 'michael@grosser.it'
  s.homepage = 'http://github.com/zendesk/delta_changes'
  s.license = 'MIT'
  s.files = Dir.glob('lib/**/*')

  s.add_runtime_dependency 'activerecord', '>= 3.2.22', '< 5.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'sqlite3', '~> 1.3.6'
  s.add_development_dependency 'bump'
  s.add_development_dependency 'wwtd'
  s.add_development_dependency 'byebug'
end
