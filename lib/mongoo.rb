module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}

  class << self
    attr_accessor :conn, :db_name, :verbose_debug
  end
end

require "forwardable"
require "mongo"

require "mongoo/async"

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
