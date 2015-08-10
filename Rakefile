require 'resque/tasks'
require 'rspec/core/rake_task'

task default: %w(spec features)

namespace 'resque' do
  task 'setup' do
    require_relative 'lib/orcid_claim'
    require_relative 'lib/orcid_update'
  end
end

desc 'run specs'
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end
