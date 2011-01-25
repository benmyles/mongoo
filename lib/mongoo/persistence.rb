module Mongoo
  class AlreadyInsertedError < Exception; end
  class NotInsertedError < Exception; end
  class InsertError < Exception; end
  class StaleUpdateError < Exception; end
  class UpdateError < Exception; end
  class RemoveError < Exception; end
  class NotValidError < Exception; end
  
  module Persistence
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods      
      def collection_name
        @collection_name ||= self.model_name.tableize
      end
      
      def collection
        @collection ||= db.collection(collection_name)
      end
      
      def db
        @db ||= Mongoo.db
      end
      
      def db=(db)
        @db = db
      end
      
      def find(query={}, opts={})
        Mongoo::Cursor.new(self, collection.find(query, opts))
      end
      
      def find_one(query={}, opts={})
        return nil unless doc = collection.find_one(query, opts)
        new(doc)
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
      !get("_id").nil?
    end
    
    def collection
      self.class.collection
    end
    
    def insert(opts={})
      _run_insert_callbacks do
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
        set_persisted_mongohash(mongohash.deep_clone)
        ret
      end
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
          update_query_hash[k] = persisted_val
        end
      end
      update_query_hash
    end
    protected :build_update_query_hash
    
  end
end