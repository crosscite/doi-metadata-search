include_recipe 'rsyslog::default'

rsyslog_file_input 'test-file' do
  file '/var/log/boot'
end
