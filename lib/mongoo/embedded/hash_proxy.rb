module Mongoo
  module Embedded
    class HashProxy

      def initialize(doc, hash, klass)
        @doc   = doc
        @hash  = hash
        @klass = klass
      end

      def build(hash)
        @klass.new(@doc,hash)
      end

      def raw
        @hash
      end

      def [](k)
        build raw[k]
      end

      def delete(k)
        raw.delete(k)
      end

      def []=(k,o)
        raw[k] = o.to_hash
      end

      def each
        raw.each { |k,v| yield(k, build(v)) }
      end

      def size
        raw.size
      end

      def keys
        raw.keys
      end

    end # HashProxy
  end # Embedded
end # Mongoo