require 'mongo'

module MongoData

  def self.db
    @db ||= Mongo::Connection.new(conf['mongo_host'])[conf['mongo_db']]
  end

  def self.coll name
    self.db[name]
  end

  def self.conf
      @conf ||= JSON.parse(File.open('conf/app.json').read)
  end

end
