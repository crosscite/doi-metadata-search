namespace :import do
  desc "Import "
  task :datacite do
    return nil unless ENV['RA'] == 'datacite'

    import = Import.new(from_date: ENV['FROM_DATE'], until_date: ENV['UNTIL_DATE'])
    number = import.get_total
    if number > 0
      import.queue_jobs
      puts "Started import of #{number} works in the background..."
    else
      puts "No works to import."
    end
  end

  task :default => :datacite
end
