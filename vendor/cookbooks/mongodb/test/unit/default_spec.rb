require 'chefspec'
require 'chefspec/berkshelf'
require 'fauxhai'

describe 'mongodb::default' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      :platform => 'ubuntu',
      :version => '12.04'
      )
  end

  it 'should install and enable mongodb' do
    chef_run.converge(described_recipe)
    expect(chef_run).to enable_service 'mongodb'
    expect(chef_run).to include_recipe('mongodb::install')
  end

  it 'should disable logpath when syslog is set' do
    chef_run.node.set.mongodb.config.syslog = true
    chef_run.converge(described_recipe)
    expect(chef_run).to_not create_directory('/var/log/mongodb')
  end

  it 'should be able to set logpath to nil, and wont create' do
    chef_run.node.set.mongodb.config.logpath = '/tmp/mongodb_config_logpath/logfile.log'
    chef_run.node.set.mongodb.config.logpath = nil
    chef_run.converge(described_recipe)
    expect(chef_run).to_not create_directory('/tmp/mongodb_config_logpath')
  end

  it 'should by default create a logpath' do
    chef_run.node.set.mongodb.config.logpath = '/tmp/mongodb_config_logpath/logfile.log'
    chef_run.converge(described_recipe)
    expect(chef_run).to create_directory('/tmp/mongodb_config_logpath')
  end
end
