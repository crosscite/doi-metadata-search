require 'mongo'

module MongoData

  def self.db
    unless @db
      config = JSON.parse(File.open('conf/app.json').read)
      config.each_pair do |key, value|
        set key.to_sym, value
      end

      @db = Mongo::Connection.new(config['mongo_host'])[config['mongo_db']]
    end
    @db
  end

  def self.coll name
    self.db[name]
  end

end
