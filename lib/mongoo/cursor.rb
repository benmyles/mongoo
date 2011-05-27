module Mongoo
  class Cursor
    include Enumerable

    attr_accessor :mongo_cursor

    def initialize(obj_class, mongo_cursor)
      @obj_class    = obj_class
      @mongo_cursor = mongo_cursor
    end

    def next_document
      if doc = @mongo_cursor.next_document
        obj_from_doc(doc)
      end
    end

    alias :next :next_document

    def each
      @mongo_cursor.each do |doc|
        yield obj_from_doc(doc)
      end
    end

    def to_a
      @mongo_cursor.to_a.collect { |doc| obj_from_doc(doc) }
    end

    def count
      @mongo_cursor.count
    end

    def sort(key_or_list, direction=nil)
      @mongo_cursor.sort(key_or_list, direction)
      self
    end

    def limit(number_to_return=nil)
      @mongo_cursor.limit(number_to_return)
      self
    end

    def skip(number_to_return=nil)
      @mongo_cursor.skip(number_to_return)
      self
    end

    def batch_size(size=0)
      @mongo_cursor.batch_size(size)
      self
    end

    def method_missing(name, *args)
      if @mongo_cursor.respond_to?(name)
        @mongo_cursor.send name, *args
      else
        super
      end
    end
  
    def obj_from_doc(doc)
      obj = nil
      if Mongoo::IdentityMap.on?
        if obj = Mongoo::IdentityMap.read(doc["_id"])
          obj.merge!(doc)
        end
      end
      obj ||= @obj_class.new(doc, true)
      Mongoo::IdentityMap.write(obj) if Mongoo::IdentityMap.on?
      obj
    end

  end
end