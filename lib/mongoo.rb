module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}

  class << self
    attr_accessor :conn_opts, :db_name, :verbose_debug

    def conn
      Thread.current[:mongoo] ||= {}
      Thread.current[:mongoo][:conn] ||= Mongo::Connection.new(*conn_opts)
    end

    def db
      Thread.current[:mongoo] ||= {}
      Thread.current[:mongoo][:db] ||= conn.db(db_name)
    end

    def reset_connection!
      if Thread.current[:mongoo]
        Thread.current[:mongoo][:db] = nil
        if Thread.current[:mongoo][:conn]
          Thread.current[:mongoo][:conn].close
          Thread.current[:mongoo][:conn] = nil
        end
      end; true
    end

    def mode
      :sync
    end
  end
end

require "forwardable"
require "mongo"

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
