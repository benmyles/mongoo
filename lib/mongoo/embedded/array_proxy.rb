module Mongoo
  module Embedded
    class ArrayProxy

      def initialize(doc, array, klass)
        @doc   = doc
        @array = array
        @klass = klass
      end

      def build(hash, i=nil)
        @klass.new(@doc, hash, i)
      end

      def raw
        @array
      end

      def [](i)
        build raw[i], i
      end

      def delete_at(i)
        raw.delete_at(i)
      end

      def []=(i,o)
        raw[i] = o.to_hash
      end

      def each
        raw.each_with_index { |v,i| yield(i, build(v, i)) }
      end

      def size
        raw.size
      end

      def keys
        (0..size-1).to_a
      end

      def first
        raw.first
      end

      def last
        raw.last
      end

      def all
        raw
      end

      alias :to_a :all

      def push(obj)
        raw << obj.to_hash; raw.index(obj.to_hash)
      end

      def <<(obj)
        push(obj.to_hash)
      end

      def empty?
        raw.empty?
      end

    end # ArrayProxy
  end # Embedded
end # Mongoo