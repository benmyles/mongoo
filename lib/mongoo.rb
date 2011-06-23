unless defined?(Mongo)
  require "mongo"
end

# Mongoo.conn = lambda { Mongo::Connection.new("localhost", 27017, :pool_size => 5, :timeout => 5) }
# Mongoo.db   = "mydb"
# Mongoo.conn => #<Mongo::Connection:0x00000100db8ac0>

module Mongoo  
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

module Mongoo
  class MongooException       < RuntimeError; end

  class AlreadyInsertedError  < MongooException; end
  class NotInsertedError      < MongooException; end
  class InsertError           < MongooException; end
  class StaleUpdateError      < MongooException; end
  class UpdateError           < MongooException; end
  class RemoveError           < MongooException; end
  class NotValidError         < MongooException; end

  class DbNameNotSet          < MongooException; end
  class ConnNotSet            < MongooException; end

  class DuplicateKeyError     < MongooException; end
  class ModifierUpdateError   < MongooException; end
  class UnknownAttributeError < MongooException; end
  class InvalidAttributeValue < MongooException; end
  class UnknownAttributeError < MongooException; end
end

require "forwardable"

require "active_support/core_ext"
require "active_model"

require "mongoo/describe_dsl"

require "mongoo/hash_ext"
require "mongoo/cursor"
require "mongoo/attribute_sanitizer"
require "mongoo/attribute_proxy"
require "mongoo/changelog"
require "mongoo/persistence"
require "mongoo/modifiers"

require "mongoo/embedded/describe_dsl"
require "mongoo/embedded/core_mixin"

require "mongoo/attributes/describe_dsl"
require "mongoo/attributes"

require "mongoo/core"
require "mongoo/base"

require "mongoo/embedded/base"
require "mongoo/embedded/hash_proxy"
require "mongoo/embedded/array_proxy"

require "mongoo/mongohash"
require "mongoo/identity_map"

require "mongoo/grid_fs/describe_dsl"
require "mongoo/grid_fs/file"
require "mongoo/grid_fs/files"
