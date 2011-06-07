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

      def ==(other)
        to_hash == other.to_hash
      end

    end
  end
end