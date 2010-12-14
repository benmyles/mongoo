module Mongoo
  INDEX_META = {}
  ATTRIBUTE_META = {}
  
  def self.db
    @db
  end
  
  def self.db=(db)
    @db = db
  end
end

require "forwardable"
require "mongo"

require "active_support/core_ext"
require "active_model"

require "mongoo/cursor"
require "mongoo/attribute_sanitizer"
require "mongoo/attribute_proxy"
require "mongoo/changelog"
require "mongoo/persistence"
require "mongoo/modifiers"
require "mongoo/base"
require "mongoo/mongohash"
