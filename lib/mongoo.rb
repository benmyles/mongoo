module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}
  
  def self.config
    { host: "127.0.0.1",
      port: 27017,
      db: "test",
      opts: {}}.merge(@config || {})
  end
  
  def self.config=(cfg)
    @config = cfg
  end
  
  def self.conn
    @conn ||= Mongo::Connection.new(config[:host], config[:port], config[:opts])
  end
  
  def self.db
    @db ||= conn.db(config[:db])
  end
  
  def self.verbose_debug
    @verbose_debug
  end
  
  def self.verbose_debug=(val)
    @verbose_debug = val
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
