$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "delta_changes"
require "#{name}/version"

Gem::Specification.new name, DeltaChanges::VERSION do |s|
  s.summary = "Additional real/virtual attribute change tracking independent of ActiveRecords"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.add_runtime_dependency "activerecord"
  s.license = "MIT"
end
