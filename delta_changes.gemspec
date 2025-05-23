require_relative 'lib/delta_changes/version'

Gem::Specification.new 'delta_changes', DeltaChanges::VERSION do |s|
  s.summary = 'Additional real/virtual attribute change tracking independent of ActiveRecords'
  s.authors = ['Michael Grosser']
  s.email = 'michael@grosser.it'
  s.homepage = 'http://github.com/zendesk/delta_changes'
  s.license = 'MIT'
  s.files = Dir.glob('lib/**/*')
  s.required_ruby_version = '>= 3.3'

  s.add_dependency 'activerecord', '>= 7.0'
end
