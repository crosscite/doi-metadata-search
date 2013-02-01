require 'rack/session/abstract/id'
require 'mongo'

module Rack
  module Session
    class Mongo < Abstract::ID

      attr_reader :mutex, :pool

      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge \
        :db_name => :sessions, :collection => :sessions, :marshal_data => true

      def initialize(app, options={})
        options = {:db         => options } if options.is_a? ::Mongo::DB
        options = {:connection => options } if options.is_a? ::Mongo::Connection
        super
        db = @default_options[:db] || begin
          conn = @default_options[:connection] || begin
            @default_options[:host] ? ::Mongo::Connection.new(*@default_options[:host].split(':')) : ::Mongo::Connection.new
          end
          conn[@default_options[:db_name].to_s]
        end
        @pool = db[@default_options[:collection].to_s]
        @pool.create_index('sid', :unique => true)
        @mutex = Mutex.new
      end

      def generate_sid
        loop do
          sid = super
          break sid unless _exists? sid
        end
      end

      def get_session(env, sid)
        with_lock(env, [nil, {}]) do
          unless sid and session = _get(sid)
            sid, session = generate_sid, {}
            _put sid, session
          end
          [sid, session]
        end
      end

      def set_session(env, session_id, new_session, options)
        with_lock(env, false) do
          _put session_id, new_session
          session_id
        end
      end

      def destroy_session(env, session_id, options)
        with_lock(env) do
          _delete(session_id)
          generate_sid unless options[:drop]
        end
      end

      def with_lock(env, default=nil)
        @mutex.lock if env['rack.multithread']
        yield
      rescue
        default
      ensure
        @mutex.unlock if @mutex.locked?
      end

    private
      def _put(sid, session)
        @pool.update({ :sid => sid },
           {"$set" => {:data  => _pack(session), :updated_at => Time.now.utc}}, :upsert => true)
      end

      def _get(sid)
        if doc = _exists?(sid)
          _unpack(doc['data'])
        end
      end

      def _delete(sid)
        @pool.remove(:sid => sid)
      end

      def _exists?(sid)
        @pool.find_one(:sid => sid)
      end

      def _pack(data)
        return nil unless data
        @default_options[:marshal_data] ? [Marshal.dump(data)].pack("m*") : data
      end

      def _unpack(packed)
        return nil unless packed
        @default_options[:marshal_data] ? Marshal.load(packed.unpack("m*").first) : packed
      end
    end
  end
end
