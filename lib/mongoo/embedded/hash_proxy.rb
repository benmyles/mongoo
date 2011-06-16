module Mongoo
  module Embedded
    class HashProxy

      def initialize(doc, hash, klass)
        @doc   = doc
        @hash  = hash
        @klass = klass
      end

      def build(hash, k=nil)
        return nil if hash.nil?
        @klass.new(@doc, hash, k)
      end

      def raw
        @hash
      end

      def [](k)
        build raw[k], k
      end

      def delete(k)
        raw.delete(k)
      end

      def []=(k,o)
        raw[k] = o.to_hash
      end

      def each
        raw.each { |k,v| yield(k, build(v, k)) }
      end

      def size
        raw.size
      end

      def keys
        raw.keys
      end

      def first
        self[keys.first]
      end

      def last
        self[keys.last]
      end

      def all
        keys.collect { |k| self[k] }
      end

      def push(obj)
        k = BSON::ObjectId.new.to_s
        self[k] = obj; k
      end

    end # HashProxy
  end # Embedded
end # Mongoo