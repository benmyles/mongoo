unless defined?(Mongo)
  require "mongo"
end

# Mongoo.conn = lambda { Mongo::Connection.new("localhost", 27017, :pool_size => 5, :timeout => 5) }
# Mongoo.db   = "mydb"
# Mongoo.conn => #<Mongo::Connection:0x00000100db8ac0>

module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}

  class << self
    attr_accessor :verbose_debug

    def conn=(conn_lambda)
      @conn_lambda = conn_lambda
      @_conn = nil
      @_db = nil
      @conn_lambda
    end

    def db=(db_name)
      @db_name = db_name
      @_db = nil
      @db_name
    end

    def conn
      @_conn ||= (@conn_lambda && @conn_lambda.call)
    end

    def db
      @_db ||= (conn && conn.db(@db_name))
    end

    def async?
      Mongo.async?
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
require "mongoo/core"
require "mongoo/base"
require "mongoo/embedded/base"
require "mongoo/embedded/array_proxy"
require "mongoo/embedded/hash_proxy"
require "mongoo/mongohash"
require "mongoo/identity_map"
