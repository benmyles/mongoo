module Mongoo
  class AlreadyInsertedError < Exception; end
  class NotInsertedError < Exception; end
  class InsertError < Exception; end
  class StaleUpdateError < Exception; end
  class UpdateError < Exception; end
  class RemoveError < Exception; end
  class NotValidError < Exception; end

  class DbNameNotSet < Exception; end
  class ConnNotSet < Exception; end

  module Persistence

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def collection_name(val=nil)
        if val
          @collection_name = val
        else
          @collection_name ||= self.model_name.tableize
        end
      end

      def conn=(conn_lambda)
        @conn_lambda = conn_lambda
        @_conn = nil
        @_db = nil
        @collection = nil
        @conn_lambda
      end

      def db=(db_name)
        @db_name = db_name
        @_db = nil
        @collection = nil
        @db_name
      end

      def conn
        @_conn ||= ((@conn_lambda && @conn_lambda.call) || Mongoo.conn)
      end

      def db
        @_db ||= begin
          if db_name = (@db_name || (@conn_lambda && Mongoo.db.name))
            conn.db(db_name)
          else
            Mongoo.db
          end
        end
      end

      def collection
        @collection ||= db.collection(collection_name)
      end

      def find(query={}, opts={})
        raw = (opts ? opts.delete(:raw) : false)
        Mongoo::Cursor.new(self, collection.find(query, opts), {raw: raw})
      end

      def find_one(query={}, opts={})
        id_map_on = Mongoo::IdentityMap.on?
        is_simple_query = nil
        is_simple_query = Mongoo::IdentityMap.simple_query?(query, opts) if id_map_on

        if id_map_on && is_simple_query
          if doc = Mongoo::IdentityMap.read(query)
            return doc
          end
        end

        raw = (opts ? opts.delete(:raw) : false)

        if doc = collection.find_one(query, opts)
          return doc.merge("_mongoo_class" => @obj_class) if opts[:raw]
          Mongoo::Cursor.new(self, nil, {raw: raw}).obj_from_doc(doc)
        end
      end

      def all
        find
      end

      def each
        find.each { |found| yield(found) }
      end

      def first
        find.limit(1).next_document
      end

      def empty?
        count == 0
      end

      def count
        collection.count
      end

      def drop
        collection.drop
      end

      def index_meta
        Mongoo::INDEX_META[self.collection_name] ||= {}
      end

      def index(spec, opts={})
        self.index_meta[spec] = opts
      end

      def create_indexes
        self.index_meta.each do |spec, opts|
          opts[:background] = true if !opts.has_key?(:background)
          collection.create_index(spec, opts)
        end; true
      end
    end # ClassMethods

    def to_param
      persisted? ? get("_id").to_s : nil
    end

    def to_key
      get("_id")
    end

    def to_model
      self
    end

    def persisted?
      @persisted == true
      #!get("_id").nil?
    end

    def collection
      self.class.collection
    end

    def insert(opts={})
      ret = _run_insert_callbacks do
        if persisted?
          raise AlreadyInsertedError, "document has already been inserted"
        end
        unless valid?
          if opts[:safe] == true
            raise Mongoo::NotValidError, "document contains errors"
          else
            return false
          end
        end
        ret = self.collection.insert(mongohash.deep_clone, opts)
        unless ret.is_a?(BSON::ObjectId)
          raise InsertError, "not an object: #{ret.inspect}"
        end
        set("_id", ret)
        @persisted = true
        set_persisted_mongohash(mongohash.deep_clone)
        ret
      end
      Mongoo::IdentityMap.write(self) if Mongoo::IdentityMap.on?
      ret
    end

    def insert!(opts={})
      insert(opts.merge(:safe => true))
    end

    def update(opts={})
      _run_update_callbacks do
        unless persisted?
          raise NotInsertedError, "document must be inserted before being updated"
        end
        unless valid?
          if opts[:safe] == true
            raise Mongoo::NotValidError, "document contains errors"
          else
            return false
          end
        end
        opts[:only_if_current] = true unless opts.has_key?(:only_if_current)
        opts[:safe] = true if !opts.has_key?(:safe) && opts[:only_if_current] == true
        update_hash = build_update_hash(self.changelog)
        return true if update_hash.empty?
        update_query_hash = build_update_query_hash(persisted_mongohash.to_key_value, self.changelog)
        if Mongoo.verbose_debug
          puts "\n* update_query_hash: #{update_query_hash.merge({"_id" => get("_id")}).inspect}\n  update_hash: #{update_hash.inspect}\n  opts: #{opts.inspect}\n"
        end
        ret = self.collection.update(update_query_hash.merge({"_id" => get("_id")}), update_hash, opts)
        if !ret.is_a?(Hash) || (ret["updatedExisting"] && ret["n"] == 1)
          set_persisted_mongohash(mongohash.deep_clone)
          @persisted = true
          true
        else
          if opts[:only_if_current]
            raise StaleUpdateError, ret.inspect
          else
            raise UpdateError, ret.inspect
          end
        end
      end
    end

    def update!(opts={})
      update(opts.merge(:safe => true))
    end

    def destroyed?
      @destroyed != nil
    end

    def new_record?
      !persisted?
    end

    def remove(opts={})
      _run_remove_callbacks do
        unless persisted?
          raise NotInsertedError, "document must be inserted before it can be removed"
        end
        ret = self.collection.remove({"_id" => get("_id")}, opts)
        if !ret.is_a?(Hash) || (ret["err"] == nil && ret["n"] == 1)
          @destroyed = true
          @persisted = false
          true
        else
          raise RemoveError, ret.inspect
        end
      end
    end

    def remove!(opts={})
      remove(opts.merge(:safe => true))
    end

    def reload
      init_from_hash(collection.find_one(get("_id")))
      @persisted = true
      set_persisted_mongohash(mongohash.deep_clone)
      true
    end

    def build_update_hash(changelog)
      update_hash = {}
      changelog.each do |op, k, v|
        update_hash["$#{op}"] ||= {}
        update_hash["$#{op}"][k] = v
      end
      update_hash
    end
    protected :build_update_hash

    def build_update_query_hash(persisted_mongohash_kv, changelog)
      update_query_hash = {}
      changelog.each do |op, k, v|
        if persisted_val = persisted_mongohash_kv[k]
          if persisted_val == []
            # work around a bug where mongo won't find a doc
            # using an empty array [] if an index is defined
            # on that field.
            persisted_val = { "$size" => 0 }
          end
          update_query_hash[k] = persisted_val
        end
      end
      update_query_hash
    end
    protected :build_update_query_hash

  end
end