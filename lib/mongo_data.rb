require 'mongo'

module MongoData
  def self.db
    @db ||= Mongo::Connection.new(ENV['DB_HOST'])[ENV['DB_NAME']]
  end

  def self.coll(name)
    db[name]
  end
end
