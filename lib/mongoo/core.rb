module Mongoo
  class Core
    include ActiveModel::Validations
    extend  ActiveModel::Naming

    include Mongoo::Embedded::CoreMixin
    include Mongoo::Attributes

    def self.describe(&block)
      Mongoo::DescribeDsl.new(self).describe(&block)
    end

    def initialize(hash={}, persisted=false)
      @persisted = persisted
      init_from_hash(hash)
      set_persisted_mongohash((persisted? ? mongohash : nil))
    end

    def ==(val)
      if val.class.to_s == self.class.to_s
        if val.persisted?
          val.id == self.id
        else
          self.mongohash.raw_hash == val.mongohash.raw_hash
        end
      end
    end

    def merge!(hash)
      if hash.is_a?(Mongoo::Mongohash)
        hash = hash.raw_hash
      end
      hash.deep_stringify_keys!
      hash = mongohash.raw_hash.deep_merge(hash)
      set_mongohash( Mongoo::Mongohash.new(hash) )
      mongohash
    end

    def init_from_hash(hash)
      unless hash.is_a?(Mongoo::Mongohash)
        hash = Mongoo::Mongohash.new(hash)
      end
      set_mongohash hash
    end
    protected :init_from_hash

    def reset_persisted_mongohash
      @persisted = true
      set_persisted_mongohash(mongohash)
    end

    def set_mongohash(mongohash)
      @mongohash = mongohash
    end
    protected :set_mongohash

    def mongohash
      @mongohash
    end

    def set_persisted_mongohash(hash)
      @serialized_persisted_mongohash = Marshal.dump(hash)
      @persisted_mongohash = nil
      true
    end
    protected :set_persisted_mongohash

    def persisted_mongohash
      @persisted_mongohash ||= begin
        if @serialized_persisted_mongohash
          Marshal.load(@serialized_persisted_mongohash)
        end
      end
    end

    def to_hash
      mongohash.to_hash
    end
  end # Core
end # Mongoo