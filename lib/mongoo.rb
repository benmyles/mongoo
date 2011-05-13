unless defined?(Mongo)
  require "mongo"
end

module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}

  class << self
    attr_accessor :verbose_debug, :db_name, :conn

    def db
      @db ||= conn.db(db_name)
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
