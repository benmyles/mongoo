require 'em-synchrony'
require 'em-synchrony/em-mongo'

module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}
  
  def self.db
    @db
  end
  
  def self.em_db
    @em_db ||= begin
      host, port = db.connection.host_to_try
      EM::Mongo::Connection.new(host, port).db(db.name)
    end
  end
  
  def self.db=(db)
    @db = db
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
