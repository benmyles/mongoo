module Mongoo
  module GridFs
    module DescribeDsl
      def grid_fs_file(name, opts={})
        define_grid_fs_file_method(name, opts)
      end

      def grid_fs_files(name, opts={})
        define_grid_fs_files_method(name, opts)
      end

      def define_grid_fs_file_method(name, opts)
        attrib_name = "gridfs_#{name}"
        attribute(attrib_name, :type => :hash)

        blk = Proc.new {
          if file = instance_variable_get("@#{name}")
            file
          else
            db_lambda = opts[:db] || lambda { self.db }
            container = get_or_set(attrib_name, {})
            file = Mongoo::GridFs::File.new(container, db_lambda)
            instance_variable_set("@#{name}", file)
          end
        }
        @klass.send(:define_method, name, &blk)
      end # define_grid_fs_file_methods

      def define_grid_fs_files_method(name, opts)
        attrib_name = "gridfs_#{name}"
        attribute(attrib_name, :type => :hash)

        blk = Proc.new {
          if files = instance_variable_get("@#{name}")
            files
          else
            db_lambda = opts[:db] || lambda { self.db }
            container = get_or_set(attrib_name, {})
            files = Mongoo::GridFs::Files.new(container, db_lambda)
            instance_variable_set("@#{name}", files)
          end
        }
        @klass.send(:define_method, name, &blk)
      end
    end # DescribeDsl
  end # GridFs
end # Mongoo

class Mongoo::DescribeDsl
  include Mongoo::GridFs::DescribeDsl
end