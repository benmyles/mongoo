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
        @obj_class.new(doc)
      end
    end
  
    alias :next :next_document
  
    def each
      @mongo_cursor.each do |doc|
        yield(@obj_class.new(doc))
      end
    end
  
    def method_missing(name, *args)
      if @mongo_cursor.respond_to?(name)
        @mongo_cursor.send name, *args
      else
        super
      end
    end
  
  end
end