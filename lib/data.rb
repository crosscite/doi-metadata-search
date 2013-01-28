# -*- coding: utf-8 -*-
require 'mongo'

# Access to mongo collections, intended for use when sinatra settings are not available,
# such as when processing resque jobs.
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
