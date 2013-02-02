require 'mongo'

module MongoData

  def self.db
    @db ||= Mongo::Connection.new(settings.mongo_host)[settings.mongo_db]
  end

  def self.coll name
    self.db[name]
  end

end
