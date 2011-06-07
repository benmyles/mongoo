module Mongoo
  module Embedded
    class ArrayProxy

      def initialize(doc, array, klass)
        @doc   = doc
        @array = array
        @klass = klass
      end

      def build(hash)
        @klass.new(@doc,hash)
      end

      def raw
        @array
      end

      def range(min=0, max=-1)
        raw[min..max].collect { |h| build(h) }
      end

      def all
        range
      end

      def each
        raw.each { |h| yield(build(h)) }
      end

      def push(o)
        raw << o.to_hash
      end

      def pop(o)
        raw.pop o.to_hash
      end

      def size
        raw.size
      end

    end # ArrayProxy
  end # Embedded
end # Mongoo