#!/usr/bin/env rake
require "./app"
require 'rspec/core/rake_task'
Dir.glob('lib/tasks/*.rake').each { |r| load r}

task default: %w(spec)

desc 'run specs'
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end
