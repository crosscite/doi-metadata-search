namespace :sidekiq do
  desc "Start sidekiq"
  task :start do
    process = SidekiqProcess.new
    puts process.start
  end

  desc "Stop sidekiq"
  task :stop do
    process = SidekiqProcess.new
    puts process.stop
  end

  desc "Quiet sidekiq"
  task :quiet do
    process = SidekiqProcess.new
    puts process.quiet
  end

  desc "Monitor sidekiq"
  task :monitor do
    process = SidekiqProcess.new
    puts process.monitor
  end
end
