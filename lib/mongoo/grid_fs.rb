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

    def self.included(base)
      base.send :extend,  ClassMethods
      base.send :include, InstanceMethods
    end

    module ClassMethods
      def grid_fs_file(name, opts={})
        Mongoo::GRID_FS_META[self.to_s] ||= {}
        Mongoo::GRID_FS_META[self.to_s]["grid_fs_file"] ||= {}
        Mongoo::GRID_FS_META[self.to_s]["grid_fs_file"][name] = opts
        define_grid_fs_file_methods
      end

      def grid_fs_files(name, opts={})
        Mongoo::GRID_FS_META[self.to_s] ||= {}
        Mongoo::GRID_FS_META[self.to_s]["grid_fs_files"] ||= {}
        Mongoo::GRID_FS_META[self.to_s]["grid_fs_files"][name] = opts
        define_grid_fs_files_methods
      end

      def define_grid_fs_file_methods
        (Mongoo::GRID_FS_META[self.to_s]["grid_fs_file"] || {}).each do |name, opts|
          attribute(name, :type => :hash) unless attributes[name.to_s]

          define_method(name) do
            if file = instance_variable_get("@#{name}")
              file
            else
              db_lambda = opts[:db] || lambda { self.db }
              container = get_or_set(name, {})
              file = Mongoo::GridFs::File.new(container, db_lambda)
              instance_variable_set("@#{name}", file)
            end
          end
        end
      end # define_grid_fs_file_methods

      def define_grid_fs_files_methods
        (Mongoo::GRID_FS_META[self.to_s]["grid_fs_files"] || {}).each do |name, opts|
          attribute(name, :type => :hash) unless attributes[name.to_s]

          define_method(name) do
            if files = instance_variable_get("@#{name}")
              files
            else
              db_lambda = opts[:db] || lambda { self.db }
              container = get_or_set(name, {})
              files = Mongoo::GridFs::Files.new(container, db_lambda)
              instance_variable_set("@#{name}", files)
            end
          end # define_method
        end
      end # define_grid_fs_files_methods
    end # ClassMethods

    module InstanceMethods
    end # InstanceMethods

  end # GridFs
end # Mongoo