unless defined?(Mongo)
  require "mongo"
end

module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}

  class << self
    attr_accessor :conn_opts, :db_name, :verbose_debug

    def conn
      @conn ||= Mongo::Connection.new(*conn_opts)
    end

    def db
      @db ||= conn.db(db_name)
    end

    def reset_connection!
      @conn.close if @conn
      @conn = nil
    end

    def mode
      Mongo.em? ? :async : :sync
    end
  end
end

require "forwardable"

require "active_support/core_ext"
require "active_model"

require "mongoo/hash_ext"
require "mongoo/cursor"
require "mongoo/attribute_sanitizer"
require "mongoo/attribute_proxy"
require "mongoo/changelog"
require "mongoo/persistence"
require "mongoo/modifiers"
require "mongoo/base"
require "mongoo/mongohash"
require "mongoo/identity_map"
