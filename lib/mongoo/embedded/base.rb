module Mongoo
  module Embedded
    class Base < Mongoo::Core

      def initialize(parent, hash={})
        @parent    = parent
        @persisted = persisted?
        init_from_hash(hash)
      end

      def persisted?
        @parent.persisted?
      end

      def db
        @parent.db
      end

      def conn
        @parent.conn
      end

      def collection_name
        @parent.collection_name
      end

      def ==(other)
        to_hash == other.to_hash
      end

      %w(update update! insert insert! save save!).each do |meth|
        define_method(meth) do |*args|
          @parent.send(meth, *args)
        end
      end

    end
  end
end