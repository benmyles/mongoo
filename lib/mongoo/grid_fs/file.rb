module Mongoo
  module GridFs

    class File
      def initialize(container_hash, db_lambda)
        @db_lambda = db_lambda
        @container_hash = container_hash
      end

      def grid
        @grid ||= Mongo::Grid.new(@db_lambda.call)
      end

      def put(*args)
        @container_hash["_id"] = grid.put(*args)
      end

      def delete(*args)
        if file_id = @container_hash["_id"]
          args ||= []
          args.unshift file_id
          res = grid.delete(*args)
          @container_hash.clear
          res
        end
      end

      def get(*args)
        if file_id = @container_hash["_id"]
          args ||= []
          args.unshift file_id
          if io = grid.get(*args)
            io.read
          end
        end
      end
    end # File

  end
end