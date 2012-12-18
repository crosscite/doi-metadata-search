require 'mongo'

module Data

  def self.db
    @db ||= do
      config = JSON.parse(File.open('conf/app.json').read)
      config.each_pair do |key, value|
        set key.to_sym, value
      end

      Mongo::Connection.new(config['mongo_host'])[config['mongo_db']]
    end
  end

  def self.coll name
    self.db[name]
  end

end
