module Mongoo
  module GridFs

    class Files
      def initialize(container_hash, db_lambda)
        @db_lambda = db_lambda
        @container_hash = container_hash
      end

      def get(*args)
        key = args.shift
        if @container_hash[key]
          Mongoo::GridFs::File.new(@container_hash[key], @db_lambda).get(*args)
        end
      end

      def put(*args)
        key = args.shift
        unless @container_hash[key]
          @container_hash[key] = {}
        end
        Mongoo::GridFs::File.new(@container_hash[key], @db_lambda).put(*args)
      end

      def delete(*args)
        key = args.shift
        if @container_hash[key]
          Mongoo::GridFs::File.new(@container_hash[key], @db_lambda).delete(*args)
        end
      end
    end # Files

  end
end