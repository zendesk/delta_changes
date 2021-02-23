require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Bundle all gemfiles"
task :bundle_all do
  Bundler.with_original_env do
    Dir["gemfiles/*.gemfile"].each do |gemfile|
      sh "BUNDLE_GEMFILE=#{gemfile} matching_bundle"
    end
  end
end


desc "Run specs under all Gemfiles"
task :spec_all do
  Bundler.with_original_env do
    Dir["gemfiles/*.gemfile"].each do |gemfile|
      sh "BUNDLE_GEMFILE=#{gemfile} rake"
    end
  end
end
