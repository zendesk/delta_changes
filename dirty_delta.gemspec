$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
name = "dirty_delta"
require "#{name}/version"

Gem::Specification.new name, DirtyDelta::VERSION do |s|
  s.summary = "Additional real/virtual attribute dirty tracking independent of ActiveRecords"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/#{name}"
  s.files = `git ls-files`.split("\n")
  s.license = "MIT"
end
