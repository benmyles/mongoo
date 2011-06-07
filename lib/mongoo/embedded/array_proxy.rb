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

      def [](index)
        if res = raw[index]
          build(res)
        end
      end

      def range(min=0, max=-1)
        if res = raw[min..max]
          res.collect { |h| build(h) }
        end
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