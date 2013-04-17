<<<<<<< HEAD
# -*- coding: utf-8 -*-
require 'mongo'

# Access to mongo collections, intended for use when sinatra settings are not available,
# such as when processing resque jobs.
=======
require 'mongo'

>>>>>>> 94ea77be3433c3974e7f221168c9f8ff2d0f1725
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
