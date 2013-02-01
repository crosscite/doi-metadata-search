rack-session-mongo
====================

Rack session store for MongoDB

<http://github.com/migrs/rack-session-mongo>

[![Build Status](https://secure.travis-ci.org/migrs/rack-session-mongo.png)](http://travis-ci.org/migrs/rack-session-mongo)

## Installation

    gem install rack-session-mongo

## Usage

Simple (localhost:27017 db:sessions, collection:sessions)

    use Rack::Session::Mongo

Set MongoDB connection

    conn = Mongo::Coneection.new('myhost', 27017)
    use Rack::Session::Mongo, conn

Set MongoDB instance

    conn = Mongo::Coneection.new('myhost', 27017)
    db = conn['myapp']
    use Rack::Session::Mongo, db

Specify DB host with some config

    use Rack::Session::Mongo, {
      :host         => 'myhost:27017',
      :db_name      => 'myapp',
      :marshal_data => false,
      :expire_after => 600
    }

## About MongoDB

- <http://www.mongodb.org/>
- <https://github.com/mongodb/mongo-ruby-driver>

## License
[rack-session-mongo](http://github.com/migrs/rack-session-mongo) is Copyright (c) 2012 [Masato Igarashi](http://github.com/migrs)(@[migrs](http://twitter.com/migrs)) and distributed under the [MIT license](http://www.opensource.org/licenses/mit-license).
