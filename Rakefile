#!/usr/bin/env rake
require "./app"
Dir.glob('lib/tasks/*.rake').each { |r| load r}

if ENV['RACK_ENV'] != 'production'
  require 'rspec/core/rake_task'
  task default: %w(spec)

  desc 'run specs'
  task :spec do
    RSpec::Core::RakeTask.new(:spec) do |t|
      t.pattern = './spec/**/*_spec.rb'
    end
  end
end
